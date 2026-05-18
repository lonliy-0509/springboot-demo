pipeline {
    agent any

    environment {
        HARBOR_URL = "47.86.237.57:80"
        HARBOR_PROJECT = "cicd-project"
        IMAGE_NAME = "springboot-demo"
        IMAGE_TAG = "${BUILD_NUMBER}"
        HARBOR_CREDENTIALS = "harbor"
        GIT_CREDENTIALS = "server-ssh"
        // 新增：生产服务器ssh凭证ID
        WEB_CREDENTIALS = "web-ssh"
        // 新增：生产服务器地址
        WEB_HOST = "47.86.238.223"
        // 新增：部署脚本路径
        WEB_SCRIPT_PATH = "/opt/apps/springboot-demo/scripts/deploy.sh"
    }

    stages {
        stage('1. 拉取代码') {
            steps {
                echo "拉取源码"
                git url: "git@github.com:lonliy-0509/springboot-demo.git", branch: "main",credentialsId: "${GIT_CREDENTIALS}"
            }
        }

        stage('2. 构建Docker镜像') {
            steps {
                sh "docker build -t ${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('3. 推送镜像到Harbor') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${HARBOR_CREDENTIALS}",
                    usernameVariable: 'HARBOR_USER',
                    passwordVariable: 'HARBOR_PASS')]) {
                    sh "docker login ${HARBOR_URL} -u ${HARBOR_USER} -p ${HARBOR_PASS}"
                }
                sh "docker push ${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('4. 清理本地镜像') {
            steps {
                sh "docker rmi ${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        // 新增：自动部署到生产环境阶段
        stage('5. 自动部署到生产环境') {
            steps {
                echo "开始部署到生产服务器..."
                withCredentials([sshUserPrivateKey(
                    credentialsId: "${WEB_CREDENTIALS}",
                    keyFileVariable: 'SSH_KEY'
                )]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i \${SSH_KEY} root@${WEB_HOST} "bash ${WEB_SCRIPT_PATH} ${IMAGE_TAG}"
		    """
                }
                echo "生产环境部署完成"
            }
        }
    }

    post {
        success {
            echo "🎉  完整CI/CD流程执行成功！"
            echo "流水线成功，版本：${IMAGE_TAG}"
            echo "访问地址: http://${WEB_HOST}"
        }
        failure {
            echo "流水线失败"
        }
    }
}

pipeline {
    agent any

    // 新增：和你界面配置对应的参数，确保逻辑完全一致
    parameters {
        string(name: 'ROLLBACK_VERSION', defaultValue: '', description: '要回滚的版本号，留空则部署最新版本')
    }

    environment {
        HARBOR_URL = "47.86.237.57:80"
        HARBOR_PROJECT = "cicd-project"
        IMAGE_NAME = "springboot-demo"
        // 核心修改：根据参数自动判断用新版本还是回滚版本
        IMAGE_TAG = "${params.ROLLBACK_VERSION == '' ? BUILD_NUMBER : params.ROLLBACK_VERSION}"
        HARBOR_CREDENTIALS = "harbor"
        GIT_CREDENTIALS = "server-ssh"
        WEB_CREDENTIALS = "web-ssh"
        WEB_HOST = "47.86.238.223"
        WEB_SCRIPT_PATH = "/opt/apps/springboot-demo/scripts/deploy.sh"
    }

    stages {
        // 1. 拉取代码：仅在部署新版本时执行（回滚时跳过）
        stage('1. 拉取代码') {
            when {
                expression { params.ROLLBACK_VERSION == '' }
            }
            steps {
                echo "拉取源码"
                git url: "git@github.com:lonliy-0509/springboot-demo.git", branch: "main",credentialsId: "${GIT_CREDENTIALS}"
            }
        }

        // 2. 构建Docker镜像：仅在部署新版本时执行（回滚时跳过）
        stage('2. 构建Docker镜像') {
            when {
                expression { params.ROLLBACK_VERSION == '' }
            }
            steps {
                sh "docker build -t ${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        // 3. 推送镜像到Harbor：仅在部署新版本时执行（回滚时跳过）
        stage('3. 推送镜像到Harbor') {
            when {
                expression { params.ROLLBACK_VERSION == '' }
            }
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

        // 4. 清理本地镜像：仅在部署新版本时执行（回滚时跳过）
        stage('4. 清理本地镜像') {
            when {
                expression { params.ROLLBACK_VERSION == '' }
            }
            steps {
                sh "docker rmi ${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        // 5. 部署/回滚阶段：无论是否填参数，都会执行
        stage('5. 自动部署到生产环境') {
            steps {
                script {
                    // 根据参数判断是部署新版本还是回滚
                    if (params.ROLLBACK_VERSION == '') {
                        echo "开始部署新版本：${IMAGE_TAG}"
                    } else {
                        echo "开始回滚到历史版本：${IMAGE_TAG}"
                    }
                }

                withCredentials([sshUserPrivateKey(
                    credentialsId: "${WEB_CREDENTIALS}",
                    keyFileVariable: 'SSH_KEY'
                )]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i \${SSH_KEY} root@${WEB_HOST} "bash ${WEB_SCRIPT_PATH} ${IMAGE_TAG}"
                    """
                }

                script {
                    if (params.ROLLBACK_VERSION == '') {
                        echo "✅ 新版本部署完成"
                    } else {
                        echo "✅ 历史版本回滚完成"
                    }
                }
            }
        }
    }

    post {
        success {
            script {
                if (params.ROLLBACK_VERSION == '') {
                    echo "🎉 完整CI/CD流程执行成功！"
                    echo "应用新版本: ${IMAGE_TAG}"
                } else {
                    echo "🎉 版本回滚成功！"
                    echo "当前应用版本: ${IMAGE_TAG}"
                }
            }
            echo "访问地址: http://${WEB_HOST}"
        }
        failure {
            echo "❌ 流程执行失败！"
        }
    }
}

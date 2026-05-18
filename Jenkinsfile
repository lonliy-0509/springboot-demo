// 固定开头：声明这是Jenkins流水线脚本
pipeline {
    // agent any 意思：任意一台Jenkins执行节点都可以运行此流水线
    // 不用指定固定服务器，通用性最强
    agent any

    // ========== 全局环境变量区（统一管理所有配置，改这里即可全局生效） ==========
    environment {
        // 私有镜像仓库Harbor的地址（填你的服务器IP/域名）
        HARBOR_URL = "47.86.237.57:80"
        // Harbor里面提前创建好的项目仓库名称
        HARBOR_PROJECT = "cicd-project"
        // 自定义镜像名称
        IMAGE_NAME = "springboot-demo"
        // 镜像版本号：调用Jenkins内置变量，每运行一次流水线数字自动+1，版本唯一
        IMAGE_TAG = "${BUILD_NUMBER}"
        // Jenkins系统中存放Harbor账号密码的【凭证ID】，和后台创建的ID必须一致
        HARBOR_CREDENTIALS = "harbor"
    }

    // ========== 流水线执行阶段（从上到下顺序执行，失败直接终止） ==========
    stages {

        // 阶段1：拉取代码
        stage('1. 拉取代码') {
            // 当前阶段要执行的操作
            steps {
                echo "拉取源码"
                // 连接Git仓库，拉取main分支所有代码
                // 自动拉取：源码、pom.xml、Dockerfile、配置文件全部拉到Jenkins工作目录
                git url: "https://github.com/lonliy-0509/springboot-demo.git", branch: "main"
            }
        }

        // 阶段2：构建Docker镜像（核心阶段，编译打包全在这里完成）
        stage('2. 构建Docker镜像') {
            steps {
                // sh = 执行Linux shell命令
                sh "docker build -t ${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG} ."
                // 命令拆分解释：
                // docker build ：构建Docker镜像
                // -t ：给镜像打上标签（命名）
                // 拼接结果示例：harbor-server/cicd-project/springboot-demo:1
                // 最后一个 . ：代表使用【当前目录】下的Dockerfile文件构建
            }
        }
        // 重点：执行这行构建命令时
        // 自动读取项目里的Dockerfile → 自动拉取Maven镜像 → 自动下载依赖 → 自动编译打包Jar
        // 【没有任何重复编译】，编译全部在Docker容器内完成

        // 阶段3：登录Harbor私有仓库 + 推送镜像
        stage('3. 推送镜像到Harbor') {
            steps {
                // withCredentials：Jenkins安全读取凭证，**脚本不写明文账号密码**
                withCredentials([usernamePassword(
                    credentialsId: "${HARBOR_CREDENTIALS}", // 匹配上面定义的凭证ID
                    usernameVariable: 'HARBOR_USER',        // 把账号赋值给这个变量
                    passwordVariable: 'HARBOR_PASS')]) {     // 把密码赋值给这个变量
                    
                    // 用读取到的账号密码登录Harbor仓库
                    sh "docker login ${HARBOR_URL} -u ${HARBOR_USER} -p ${HARBOR_PASS}"
                }

                // 登录成功后，把本地构建好的镜像推送到远程Harbor仓库
                sh "docker push ${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        // 阶段4：清理本地镜像（运维必备）
        stage('4. 清理本地镜像') {
            steps {
                // docker rmi = 删除镜像
                // 镜像已经推送到云端Harbor，本地留着占用磁盘，直接删除
                sh "docker rmi ${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }
    }

    // ========== 流水线执行完毕后 后置判断 ==========
    post {
        // 所有阶段全部执行成功后触发
        success { 
            echo "流水线成功，版本：${IMAGE_TAG}" 
        }
        // 任意阶段报错、失败，立刻触发
        failure { 
            echo "流水线失败" 
        }
    }
}
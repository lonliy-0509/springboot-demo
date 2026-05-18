# ==========================================
# 第一阶段：构建阶段（仅用于编译打包，不会进入最终镜像）
# ==========================================

# 1. 指定构建阶段的基础镜像
# 使用带 JDK17 的 Maven 镜像，专门用来编译 Java 项目
# eclipse-temurin 是 OpenJDK 的稳定发行版，3.9.6 是 Maven 版本
FROM maven:3.9.6-eclipse-temurin-17 AS builder

# 2. 设置容器内的工作目录
# 后面所有命令默认都在 /app 目录下执行，相当于自动 cd /app
WORKDIR /app

# 3. 先复制 pom.xml 文件
# 利用 Docker 的分层缓存机制：只要 pom.xml 不变，依赖就不会重新下载
COPY pom.xml .

# 4. 提前下载所有 Maven 依赖
# 把依赖缓存到镜像层，下次构建时如果 pom.xml 没改，直接跳过这一步
RUN mvn dependency:go-offline

# 5. 复制项目的源代码
# 把本地的 src 目录复制到容器内的 /app/src 目录
COPY src ./src

# 6. 执行 Maven 打包命令
# clean：先清理上一次的构建产物
# package：编译并打包成可执行 Jar 包
# -DskipTests：跳过单元测试，加快构建速度
RUN mvn clean package -DskipTests

# ==========================================
# 第二阶段：运行阶段（最终只保留这部分内容）
# ==========================================

# 7. 指定运行阶段的基础镜像
# 使用精简的 JRE17 Alpine 镜像，只包含 Java 运行环境，体积极小（约 80MB，这里的JRE版本必须和第一阶段的JDK版本完全一致
FROM eclipse-temurin:17-jre-alpine

# 8. 设置运行阶段的工作目录
WORKDIR /app

# 9. 从构建阶段复制打好的 Jar 包
# --from=builder：表示从第一阶段的 builder 镜像中复制文件
# /app/target/*.jar：复制构建生成的所有 Jar 包（不管名字是什么）
# 目标文件名：app.jar
COPY --from=builder /app/target/*.jar app.jar

# 10. 声明容器要暴露的端口
# 这只是一个文档声明，运行时还是要通过 -p 映射端口
# 必须和 application.properties 里的 server.port=8080 保持一致
EXPOSE 8080

# 11. 容器启动命令
# 启动 Spring Boot 应用，运行打包好的 app.jar
#为什么用ENTRYPOINT而不是CMD，CMD会被Docker容器启动命令行参数覆盖
ENTRYPOINT ["java", "-jar", "app.jar"]
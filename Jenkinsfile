pipeline {
    agent {
        kubernetes {
            label 'jenkins-k8s-agent'
            defaultContainer 'jnlp'
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins-agent: kubectl-maven
spec:
  containers:
    - name: jnlp
      image: jenkins/inbound-agent:latest
      args: ['\$(JENKINS_SECRET)', '\$(JENKINS_NAME)']
    - name: kubectl
      image: bitnami/kubectl:latest
      command: ["cat"]
      tty: true
    - name: maven
      image: maven:3.9.3-eclipse-temurin-17
      command: ["cat"]
      tty: true
"""
        }
    }
    environment {
        SCRIPTS_DIR = "${WORKSPACE}/gitops-envs/scripts"
        APPS_DIR    = "${WORKSPACE}/gitops-apps/apps"
        ENV_NAMES   = ["tst0","tst1"]  // Defina aqui os ambientes que deseja criar
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                // Garante que os scripts têm permissão de execução
                sh "chmod +x ${SCRIPTS_DIR}/*.sh"
            }
        }
        stage('Preparar ambientes') {
            steps {
                echo "Ambientes a criar: ${ENV_NAMES}"
            }
        }
        stage('Criar ambientes') {
            steps {
                script {
                    def stepsForParallel = [:]
                    for (envName in ENV_NAMES) {
                        stepsForParallel[envName] = {
                            container('kubectl') {
                                echo "Criando ambiente ${envName}"
                                sh "${SCRIPTS_DIR}/create_env.sh ${envName} ${APPS_DIR}"
                            }
                        }
                    }
                    parallel stepsForParallel
                }
            }
        }
        stage('Executar testes') {
            steps {
                script {
                    for (envName in ENV_NAMES) {
                        container('maven') {
                            echo "Rodando testes para ambiente ${envName}"
                            sh "mvn test -Dapp.url=http://bff-callback.${envName}.svc.cluster.local:8080"
                        }
                    }
                }
            }
        }
    }
    post {
        always {
            script {
                for (envName in ENV_NAMES) {
                    container('kubectl') {
                        echo "Destruindo ambiente ${envName}"
                        sh """
                        ${SCRIPTS_DIR}/destroy_env.sh ${envName} || echo "Falha ao destruir ${envName}"
                        """
                    }
                }
            }
        }
    }
}


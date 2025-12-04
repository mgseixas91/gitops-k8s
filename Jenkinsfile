pipeline {
    agent any

    environment {
        // Lista de ambientes como string (não pode ser lista diretamente)
        ENV_NAMES_STR = "tst0,tst1"
        GIT_REPO = "https://github.com/mgseixas91/gitops-k8s.git"
        WORKSPACE_SCRIPTS = "gitops-envs/scripts"
        WORKSPACE_APPS = "gitops-apps/apps"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: "${env.GIT_REPO}", credentialsId: 'github-cred'
            }
        }

        stage('Preparar ambientes') {
            steps {
                script {
                    ENV_NAMES = ENV_NAMES_STR.split(',')
                    echo "Ambientes a criar: ${ENV_NAMES}"
                }
            }
        }

        stage('Verificar scripts') {
            steps {
                script {
                    sh "ls -l ${WORKSPACE_SCRIPTS}"
                    sh "chmod +x ${WORKSPACE_SCRIPTS}/*.sh"
                }
            }
        }

        stage('Criar ambientes') {
            steps {
                script {
                    def branches = [:]
                    for (envName in ENV_NAMES) {
                        def name = envName // necessário para closure
                        branches["Criar ${name}"] = {
                            echo "Criando ambiente ${name}"
                            sh "${WORKSPACE_SCRIPTS}/create_env.sh ${name} ${WORKSPACE_APPS}"
                        }
                    }
                    parallel branches
                }
            }
        }

        stage('Executar testes') {
            steps {
                script {
                    for (envName in ENV_NAMES) {
                        echo "Rodando testes para ambiente ${envName}"
                        sh "${WORKSPACE_SCRIPTS}/run_tests.sh ${envName}"
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                echo "Destruindo ambientes..."
                for (envName in ENV_NAMES) {
                    sh """
                        ${WORKSPACE_SCRIPTS}/destroy_env.sh ${envName} ${WORKSPACE_APPS} || echo "Falha ao destruir ${envName}"
                    """
                }
            }
        }
    }
}


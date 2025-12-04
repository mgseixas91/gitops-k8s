pipeline {
    agent any

    parameters {
        string(name: 'ENVS', defaultValue: 'tst0,tst1', description: 'Lista de ambientes separados por vírgula')
    }

    stages {
        stage('Checkout') {
            steps {
                // Faz o checkout do repo com apps e envs
                checkout scm
            }
        }

        stage('Preparar ambientes') {
            steps {
                script {
                    // Convertendo string de parâmetros em lista
                    def envNames = params.ENVS.split(',')
                    echo "Ambientes a criar: ${envNames}"
                    // Salvando em variável global para outras stages
                    env.ENV_NAMES = envNames.join(',')
                }
            }
        }

        stage('Verificar scripts') {
            steps {
                script {
                    // Garantir que os scripts existem e têm permissão
                    sh "ls -l ${env.WORKSPACE}/gitops-envs/scripts"
                    sh "chmod +x ${env.WORKSPACE}/gitops-envs/scripts/*.sh"
                }
            }
        }

        stage('Criar ambientes') {
            steps {
                script {
                    def branches = [:]
                    for (envName in env.ENV_NAMES.split(',')) {
                        def envCopy = envName
                        branches[envCopy] = {
                            echo "Criando ambiente ${envCopy}"
                            sh "${env.WORKSPACE}/gitops-envs/scripts/create_env.sh ${envCopy}"
                        }
                    }
                    parallel branches
                }
            }
        }

        stage('Executar testes') {
            steps {
                script {
                    for (envName in env.ENV_NAMES.split(',')) {
                        echo "Rodando testes para ambiente ${envName}"
                        def APP_URL="http://bff-callback.${envName}.svc.cluster.local:8080"
                        sh "mvn test -Dapp.url=${APP_URL}"
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                echo "Destruindo ambientes..."
                for (envName in env.ENV_NAMES.split(',')) {
                    sh "${env.WORKSPACE}/gitops-envs/scripts/destroy_env.sh ${envName} || echo 'Falha ao destruir ${envName}'"
                }
            }
        }
    }
}


// Defina os ambientes que quer criar
def ENV_NAMES = ["tst0", "tst1"]

pipeline {
    agent none  // Não define agente global, vamos definir por stage

    stages {

        stage('Checkout') {
            agent { label 'jenkins-agent-k8s' } // label do pod template
            steps {
                checkout scm
            }
        }

        stage('Preparar ambientes') {
            agent { label 'jenkins-agent-k8s' }
            steps {
                script {
                    echo "Ambientes a criar: ${ENV_NAMES}"
                }
            }
        }

        stage('Verificar scripts') {
            agent { label 'jenkins-agent-k8s' }
            steps {
                script {
                    sh '''
                        chmod +x gitops-envs/scripts/create_env.sh \
                                gitops-envs/scripts/destroy_env.sh \
                                gitops-envs/scripts/run_tests.sh
                        ls -l gitops-envs/scripts
                    '''
                }
            }
        }

        stage('Criar ambientes') {
            agent { label 'jenkins-agent-k8s' }
            steps {
                script {
                    def branches = [:]
                    for (envName in ENV_NAMES) {
                        branches["Criar ${envName}"] = {
                            sh "gitops-envs/scripts/create_env.sh ${envName} gitops-apps/apps"
                        }
                    }
                    parallel branches
                }
            }
        }

        stage('Executar testes') {
            agent { label 'jenkins-agent-k8s' }
            steps {
                script {
                    for (envName in ENV_NAMES) {
                        echo "Rodando testes para ambiente ${envName}"
                        sh "gitops-envs/scripts/run_tests.sh ${envName}"
                    }
                }
            }
        }
    }

    post {
        always {
            agent { label 'jenkins-agent-k8s' }
            script {
                echo "Destruindo ambientes..."
                for (envName in ENV_NAMES) {
                    sh "gitops-envs/scripts/destroy_env.sh ${envName} gitops-apps/apps || echo 'Falha ao destruir ${envName}'"
                }
            }
        }
    }
}


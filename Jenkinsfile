pipeline {
    agent any

    parameters {
        string(name: 'NUM_AMBIENTES', defaultValue: '2', description: 'Número de ambientes a criar')
    }

    environment {
        WORKSPACE_SCRIPTS = "${env.WORKSPACE}/gitops-envs/scripts"
        WORKSPACE_APPS    = "${env.WORKSPACE}/gitops-apps/apps"
    }

    stages {

        stage('Preparar ambientes') {
            steps {
                script {
                    int numAmbientes = params.NUM_AMBIENTES.toInteger()
                    env.ENV_NAMES = (0..<numAmbientes).collect { "tst${it}" }
                    echo "Ambientes a criar: ${env.ENV_NAMES}"
                }
            }
        }

        stage('Verificar scripts') {
            steps {
                script {
                    sh "chmod +x ${WORKSPACE_SCRIPTS}/*.sh"
                    sh "ls -l ${WORKSPACE_APPS}"
                }
            }
        }

        stage('Criar ambientes') {
            steps {
                script {
                    for (amb in env.ENV_NAMES) {
                        echo "Criando ambiente ${amb}"
                        sh "${WORKSPACE_SCRIPTS}/create_env.sh ${amb} ${WORKSPACE_APPS}"
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finalizada"
        }
    }
}


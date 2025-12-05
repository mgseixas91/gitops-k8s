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
                    int num = params.NUM_AMBIENTES.toInteger()
                    AMBIENTES = (0..<num).collect { "tst${it}" }   // VAR LOCAL!!
                    echo "Ambientes a criar: ${AMBIENTES}"
                }
            }
        }

        stage('Verificar scripts') {
            steps {
                sh "chmod +x ${WORKSPACE_SCRIPTS}/*.sh"
                sh "ls -l ${WORKSPACE_APPS}"
            }
        }

        stage('Criar ambientes') {
            steps {
                script {
                    for (amb in AMBIENTES) {
                        echo "Criando ambiente ${amb}"
                        sh "${WORKSPACE_SCRIPTS}/create_env.sh ${amb} ${WORKSPACE_APPS}"
                    }

                    input message: 'Ambientes criados. Confirmar para prosseguir?', ok: 'Sim'
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


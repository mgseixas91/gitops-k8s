pipeline {
    agent any

    parameters {
        string(name: 'NUM_AMBIENTES', defaultValue: '2', description: 'Número de ambientes a criar')
    }

    environment {
        // Aqui você pode definir variáveis globais
        WORKSPACE_SCRIPTS = "${env.WORKSPACE}/gitops-envs/scripts"
        WORKSPACE_APPS    = "${env.WORKSPACE}/gitops-apps/apps"
    }

    stages {

        stage('Preparar ambientes') {
            steps {
                script {
                    // Converte o número de ambientes em lista
                    int numAmbientes = params.NUM_AMBIENTES.toInteger()
                    env.ENV_NAMES = (0..<numAmbientes).collect { "tst${it}" }
                    echo "Ambientes a criar: ${env.ENV_NAMES}"
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
                    for (amb in env.ENV_NAMES.tokenize(',')) {
                        echo "Criando ambiente ${amb}"
                        sh "${WORKSPACE_SCRIPTS}/create_env.sh ${amb} ${WORKSPACE_APPS}"
                    }

                    // Input para confirmar que os ambientes subiram
                    input message: 'Ambientes criados. Confirmar para prosseguir?', ok: 'Sim'
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline de criação de ambientes finalizada"
        }
    }
}


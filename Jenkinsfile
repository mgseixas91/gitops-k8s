pipeline {
    agent any
    environment {
        SCRIPTS_DIR = "${WORKSPACE}/gitops-envs/scripts"
        APPS_DIR = "${WORKSPACE}/gitops-apps/apps"
    }
    stages {
        stage('Preparar ambientes') {
            steps {
                script {
                    // Pergunta ao usuário quantos ambientes criar
                    def numAmbientes = input(
                        id: 'userInput',
                        message: 'Quantos ambientes deseja criar?',
                        parameters: [string(defaultValue: '2', description: 'Número de ambientes', name: 'NUM_AMBIENTES')]
                    )
                    // Cria lista de nomes de ambiente: tst0, tst1, ...
                    envNames = (0..<numAmbientes.toInteger()).collect { "tst${it}" }
                    echo "Ambientes a criar: ${envNames}"
                }
            }
        }

        stage('Verificar scripts') {
            steps {
                script {
                    // Confere scripts e dá permissão de execução
                    sh "ls -l ${SCRIPTS_DIR}"
                    sh "chmod +x ${SCRIPTS_DIR}/*.sh"
                }
            }
        }

        stage('Criar ambientes') {
            steps {
                script {
                    def parallelSteps = [:]
                    for (envName in envNames) {
                        parallelSteps[envName] = {
                            echo "Criando ambiente ${envName}"
                            sh """
                                ${SCRIPTS_DIR}/create_env.sh ${envName} "${APPS_DIR}" || echo 'Falha ao criar ${envName}'
                            """
                        }
                    }
                    parallel parallelSteps
                }
            }
        }

        stage('Executar testes') {
            steps {
                script {
                    for (envName in envNames) {
                        echo "Rodando testes para ambiente ${envName}"
                        sh """
                            mvn test -Dapp.url=http://bff-callback.${envName}.svc.cluster.local:8080 || echo 'Falha nos testes para ${envName}'
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                echo "Destruindo ambientes..."
                for (envName in envNames) {
                    sh """
                        ${SCRIPTS_DIR}/destroy_env.sh ${envName} || echo 'Falha ao destruir ${envName}'
                    """
                }
            }
        }
    }
}


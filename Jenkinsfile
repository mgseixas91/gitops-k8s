pipeline {
    agent { label 'jenkins-agent-k8s' }  // label do seu Pod Template Kubernetes

    environment {
        // Lista de ambientes a serem criados será preenchida pelo input
        ENV_NAMES = ''
        APP_DIR = 'gitops-apps/apps'
        SCRIPTS_DIR = 'gitops-envs/scripts'
    }

    stages {

        stage('Preparar ambientes') {
            steps {
                script {
                    // Input para definir os ambientes
                    def input_env = input(
                        id: 'envInput', 
                        message: 'Quantos ambientes deseja criar e quais?', 
                        parameters: [
                            string(name: 'ENV_NAMES', defaultValue: 'tst0,tst1', description: 'Informe nomes separados por vírgula')
                        ]
                    )
                    // Converter string em lista
                    ENV_NAMES = input_env.ENV_NAMES.split(',')
                    echo "Ambientes a criar: ${ENV_NAMES}"
                }
            }
        }

        stage('Verificar scripts') {
            steps {
                script {
                    // Garantir permissões de execução
                    sh "chmod +x ${SCRIPTS_DIR}/*.sh"
                    sh "ls -l ${SCRIPTS_DIR}"
                }
            }
        }

        stage('Criar ambientes') {
            steps {
                script {
                    for (envName in ENV_NAMES) {
                        echo "Criando ambiente ${envName}"
                        container('kubectl') {
                            sh "${SCRIPTS_DIR}/create_env.sh ${envName} ${APP_DIR} || true"
                        }
                    }

                    // Input para confirmar continuação
                    def cont = input(
                        id: 'continueTests',
                        message: 'Ambientes criados. Deseja executar os testes?',
                        parameters: [booleanParam(defaultValue: true, description: '', name: 'Continuar?')]
                    )
                    if (!cont) {
                        error("Pipeline interrompido pelo usuário após criação de ambientes")
                    }
                }
            }
        }

        stage('Executar testes') {
            steps {
                script {
                    for (envName in ENV_NAMES) {
                        echo "Executando testes para ${envName}"
                        container('maven') {
                            sh "${SCRIPTS_DIR}/run_tests.sh ${envName} || true"
                        }
                    }

                    // Input para decidir se deseja destruir os ambientes
                    def destroy = input(
                        id: 'destroyInput',
                        message: 'Deseja destruir os ambientes?',
                        parameters: [booleanParam(defaultValue: true, description: '', name: 'Destruir?')]
                    )

                    if (destroy) {
                        for (envName in ENV_NAMES) {
                            echo "Destruindo ambiente ${envName}"
                            container('kubectl') {
                                sh "${SCRIPTS_DIR}/destroy_env.sh ${envName} ${APP_DIR} || true"
                            }
                        }
                    } else {
                        echo "Ambientes mantidos conforme escolha do usuário"
                    }
                }
            }
        }
    }

    post {
        failure {
            echo "Pipeline falhou!"
        }
        success {
            echo "Pipeline finalizado com sucesso!"
        }
    }
}


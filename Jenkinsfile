pipeline {
    agent any

    environment {
        ACR_SECRET_NAMESPACE = 'acr'
        ACR_SECRET_NAME = 'acr-secret'
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Definir quantidade de novos ambientes') {
            steps {
                script {
                    // Variável global
                    QTD_AMBIENTES = input(
                        message: 'Quantos novos ambientes deseja criar?',
                        parameters: [
                            [$class: 'StringParameterDefinition', defaultValue: '1', description: 'Informe um número', name: 'Quantidade']
                        ]
                    ).toInteger()
                    echo "Quantidade de novos ambientes a criar: ${QTD_AMBIENTES}"
                }
            }
        }

        stage('Preparar ambientes') {
            steps {
                script {
                    // Variáveis globais para controlar os ambientes
                    AMBIENTES_A_CRIAR = []
                    TODOS_AMBIENTES = []

                    def existingNamespaces = sh(
                        script: "kubectl get ns --no-headers -o custom-columns=:metadata.name | grep ^tst || true",
                        returnStdout: true
                    ).trim().split('\n')

                    echo "Ambientes existentes: ${existingNamespaces}"

                    // Gerar nomes dos novos namespaces
                    for (int i = 0; i < QTD_AMBIENTES; i++) {
                        def nsName = "tst${existingNamespaces.size() + i}"
                        AMBIENTES_A_CRIAR.add(nsName)
                        TODOS_AMBIENTES.add(nsName)
                    }

                    echo "Novos ambientes a criar: ${AMBIENTES_A_CRIAR}"
                    echo "Todos ambientes para certs e secrets: ${TODOS_AMBIENTES}"
                }
            }
        }

        stage('Verificar scripts') {
            steps {
                sh '''
                    chmod +x gitops-envs/scripts/*.sh
                    ls -l gitops-apps/apps
                '''
            }
        }

        stage('Gerar san.cnf dinamicamente') {
            steps {
                script {
                    TODOS_AMBIENTES.each { ns ->
                        def sanFile = "certs/san-${ns}.cnf"
                        writeFile file: sanFile, text: """
                        [SAN]
                        subjectAltName=DNS:${ns}.example.com
                        """
                        echo "Arquivo san.cnf gerado: ${sanFile}"
                    }
                }
            }
        }

        stage('Criar ambientes e certificados') {
            steps {
                script {
                    AMBIENTES_A_CRIAR.each { ns ->
                        echo "Criando/validando ambiente ${ns}"

                        // Criar namespace se não existir
                        sh """
                        if ! kubectl get ns ${ns}; then
                            kubectl create ns ${ns}
                        else
                            echo "[INFO] Namespace ${ns} já existe"
                        fi
                        """

                        // Copiar secret do namespace acr
                        sh """
                        kubectl get secret ${ACR_SECRET_NAME} -n ${ACR_SECRET_NAMESPACE} -o yaml | \
                        sed "s/namespace: ${ACR_SECRET_NAMESPACE}/namespace: ${ns}/" | \
                        kubectl apply -f -
                        """
                    }

                    // Aqui você pode chamar seus scripts de certs/env
                    sh """
                    gitops-envs/scripts/create_certs.sh
                    gitops-envs/scripts/create_env.sh
                    """
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline finalizada'
        }
        failure {
            echo 'Ocorreu um erro durante a execução da pipeline'
        }
    }
}


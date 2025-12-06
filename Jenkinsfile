pipeline {
    agent any

    environment {
        ACR_SECRET_NAME = "acr-secret"
        ACR_SECRET_NAMESPACE = "acr"
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
                    QTD_AMBIENTES = input(
                        message: 'Quantos novos ambientes deseja criar?',
                        parameters: [string(defaultValue: '1', description: '', name: 'QTD')]
                    ).toInteger()

                    echo "Quantidade de novos ambientes a criar: ${QTD_AMBIENTES}"
                }
            }
        }

        stage('Preparar ambientes') {
            steps {
                script {
                    // Buscar namespaces existentes que começam com "tst"
                    EXISTENTES = sh(
                        script: "kubectl get ns --no-headers -o custom-columns=:metadata.name | grep ^tst || true",
                        returnStdout: true
                    ).trim().split("\n").findAll{ it }

                    echo "Ambientes existentes: ${EXISTENTES}"

                    // Criar lista de novos namespaces
                    AMBIENTES_A_CRIAR = (1..QTD_AMBIENTES).collect { i ->
                        def ns = "tst${EXISTENTES.size() + i - 1}"
                        ns
                    }

                    echo "Novos ambientes a criar: ${AMBIENTES_A_CRIAR}"
                }
            }
        }

        stage('Verificar scripts') {
            steps {
                sh '''
                    chmod +x gitops-envs/scripts/create_certs.sh
                    chmod +x gitops-envs/scripts/create_env.sh
                    chmod +x gitops-envs/scripts/create_registry_secret.sh
                    chmod +x gitops-envs/scripts/destroy_env.sh
                    chmod +x gitops-envs/scripts/run_tests.sh
                '''
            }
        }

        stage('Gerar san.cnf dinamicamente') {
            steps {
                script {
                    AMBIENTES_A_CRIAR.each { ns ->
                        def sanFile = "certs/san-${ns}.cnf"
                        writeFile file: sanFile, text: """[SAN]
DNS.1 = ${ns}.example.com
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

                        // Reaplicar secret do namespace acr
                        sh """
                        kubectl get secret ${ACR_SECRET_NAME} -n ${ACR_SECRET_NAMESPACE} -o yaml | \
                        sed "s/namespace: ${ACR_SECRET_NAMESPACE}/namespace: ${ns}/" | \
                        kubectl apply -f -
                        """

                        // Gerar certificados
                        def sanFile = "certs/san-${ns}.cnf"
                        sh """
                        gitops-envs/scripts/create_certs.sh ${ns} ${sanFile} certs/
                        """

                        // Criar o ambiente (ex.: configmaps, roles, etc.)
                        sh """
                        gitops-envs/scripts/create_env.sh ${ns}
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finalizada"
        }
        failure {
            echo "Ocorreu um erro durante a execução da pipeline"
        }
    }
}


pipeline {
    agent any

    environment {
        GIT_REPO = 'https://github.com/mgseixas91/gitops-k8s.git'
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout([$class: 'GitSCM',
                          branches: [[name: 'main']],
                          doGenerateSubmoduleConfigurations: false,
                          extensions: [],
                          userRemoteConfigs: [[url: "${env.GIT_REPO}"]]])
            }
        }

        stage('Definir quantidade de novos ambientes') {
            steps {
                script {
                    // Variável global
                    env.QTD_AMBIENTES = input(
                        message: 'Quantos novos ambientes deseja criar?',
                        parameters: [string(defaultValue: '1', description: 'Número de ambientes', name: 'QTD')]
                    )
                    echo "Quantidade de novos ambientes a criar: ${env.QTD_AMBIENTES}"
                }
            }
        }

        stage('Preparar ambientes') {
            steps {
                script {
                    def EXISTENTES = sh(
                        script: "kubectl get ns --no-headers -o custom-columns=:metadata.name | grep ^tst || true",
                        returnStdout: true
                    ).trim().split("\n").findAll { it }

                    def AMBIENTES_A_CRIAR = (EXISTENTES.size()..<(EXISTENTES.size() + env.QTD_AMBIENTES.toInteger())).collect { "tst${it}" }

                    env.TODOS_AMBIENTES = AMBIENTES_A_CRIAR.join(',')

                    echo "Ambientes existentes: ${EXISTENTES}"
                    echo "Novos ambientes a criar: ${AMBIENTES_A_CRIAR}"
                    echo "Todos ambientes para certs e secrets: ${AMBIENTES_A_CRIAR}"
                }
            }
        }

        stage('Verificar scripts') {
            steps {
                sh '''
                    chmod +x gitops-envs/scripts/create_certs.sh \
                             gitops-envs/scripts/create_env.sh \
                             gitops-envs/scripts/create_registry_secret.sh \
                             gitops-envs/scripts/destroy_env.sh \
                             gitops-envs/scripts/run_tests.sh
                '''
            }
        }

        stage('Gerar san.cnf dinamicamente') {
            steps {
                script {
                    def todos = env.TODOS_AMBIENTES.split(',')
                    todos.each { ns ->
                        def sanFile = "certs/san-${ns}.cnf"
                        writeFile file: sanFile, text: """
                        [ req ]
                        distinguished_name = req_distinguished_name
                        req_extensions = v3_req
                        prompt = no

                        [ req_distinguished_name ]
                        CN = ${ns}.example.com

                        [ v3_req ]
                        keyUsage = keyEncipherment, dataEncipherment
                        extendedKeyUsage = serverAuth
                        subjectAltName = @alt_names

                        [ alt_names ]
                        DNS.1 = ${ns}.example.com
                        DNS.2 = ${ns}
                        """
                        echo "Arquivo san.cnf gerado: ${sanFile}"
                    }
                }
            }
        }

        stage('Criar ambientes e certificados') {
            steps {
                script {
                    def todos = env.TODOS_AMBIENTES.split(',')
                    todos.each { ns ->
                        echo "Criando/validando ambiente ${ns}"

                        // Criar namespace se não existir
                        def nsExist = sh(script: "kubectl get ns ${ns}", returnStatus: true)
                        if (nsExist != 0) {
                            sh "kubectl create ns ${ns}"
                        }

                        // Reaplicar secret acr-secret
                        sh """
                            kubectl get secret acr-secret -n acr -o yaml | \
                            sed 's/namespace: acr/namespace: ${ns}/' | \
                            kubectl apply -f -
                        """

                        // Gerar certificados usando san.cnf
                        sh "gitops-envs/scripts/create_certs.sh ${ns} certs/san-${ns}.cnf certs/"
                    }
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


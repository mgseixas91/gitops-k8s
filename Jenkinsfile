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
                    def QTD_AMBIENTES = input(
                        message: 'Quantos novos ambientes deseja criar?',
                        parameters: [string(defaultValue: '1', description: 'Número de ambientes', name: 'QTD')]
                    )
                    echo "Quantidade de novos ambientes a criar: ${QTD_AMBIENTES}"
                }
            }
        }

        stage('Preparar ambientes') {
            steps {
                script {
                    // Buscar namespaces existentes
                    def EXISTENTES = sh(
                        script: "kubectl get ns --no-headers -o custom-columns=:metadata.name | grep ^tst || true",
                        returnStdout: true
                    ).trim().split("\n").findAll { it }

                    // Definir novos ambientes
                    def AMBIENTES_A_CRIAR = (EXISTENTES.size()..<(EXISTENTES.size() + QTD_AMBIENTES.toInteger())).collect { "tst${it}" }

                    // Todos ambientes para certs/secrets
                    def TODOS_AMBIENTES = AMBIENTES_A_CRIAR

                    echo "Ambientes existentes: ${EXISTENTES}"
                    echo "Novos ambientes a criar: ${AMBIENTES_A_CRIAR}"
                    echo "Todos ambientes para certs e secrets: ${TODOS_AMBIENTES}"
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
                    ls -l gitops-apps/apps
                '''
            }
        }

        stage('Gerar san.cnf dinamicamente') {
            steps {
                script {
                    TODOS_AMBIENTES.each { ns ->
                        writeFile file: "certs/san-${ns}.cnf", text: "conteúdo do san.cnf para ${ns}"
                        echo "Arquivo san.cnf gerado: certs/san-${ns}.cnf"
                    }
                }
            }
        }

        stage('Criar ambientes e certificados') {
            steps {
                script {
                    TODOS_AMBIENTES.each { ns ->
                        echo "Criando/validando ambiente ${ns}"

                        // Criar namespace se não existir
                        def nsExist = sh(script: "kubectl get ns ${ns}", returnStatus: true)
                        if (nsExist != 0) {
                            sh "kubectl create ns ${ns}"
                        }

                        // Criar/reaplicar secret acr-secret
                        sh """
                            kubectl get secret acr-secret -n acr -o yaml | \
                            sed 's/namespace: acr/namespace: ${ns}/' | \
                            kubectl apply -f -
                        """

                        // Gerar certificados
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


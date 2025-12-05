pipeline {
    agent any

    environment {
        CERTS_DIR = "${WORKSPACE}/certs"
        APPS_DIR = "${WORKSPACE}/gitops-apps/apps"
        ENVS_SCRIPTS = "${WORKSPACE}/gitops-envs/scripts"
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
                    // Pergunta quantos ambientes criar
                    int qtd = input(
                        message: 'Quantos novos ambientes deseja criar?',
                        parameters: [
                            [$class: 'StringParameterDefinition', defaultValue: '1', description: 'Informe um número', name: 'Quantidade']
                        ]
                    ).toInteger()

                    echo "Quantidade de novos ambientes a criar: ${qtd}"
                    QTD_AMBIENTES = qtd
                }
            }
        }

        stage('Preparar ambientes') {
            steps {
                script {
                    // Ambientes existentes no cluster
                    def EXISTENTES = sh(
                        script: "kubectl get ns --no-headers -o custom-columns=:metadata.name | grep ^tst || true",
                        returnStdout: true
                    ).trim().split("\n").findAll { it }

                    echo "Ambientes existentes: ${EXISTENTES}"

                    // Descobre os próximos ambientes sequenciais
                    int maxIndex = EXISTENTES.collect { it.replaceAll("tst", "").toInteger() }.max() ?: -1
                    AMBIENTES_A_CRIAR = (1..QTD_AMBIENTES).collect { i -> "tst${maxIndex + i}" }

                    echo "Novos ambientes a criar: ${AMBIENTES_A_CRIAR.join(', ')}"

                    // Todos ambientes para gerar certificados e secrets
                    TODOS_AMBIENTES = (EXISTENTES + AMBIENTES_A_CRIAR).unique()
                    echo "Todos ambientes para certs e secrets: ${TODOS_AMBIENTES.join(', ')}"
                }
            }
        }

        stage('Verificar scripts') {
            steps {
                sh """
                    chmod +x ${ENVS_SCRIPTS}/*.sh
                    ls -l ${APPS_DIR}
                """
            }
        }

        stage('Gerar san.cnf dinamicamente') {
            steps {
                script {
                    TODOS_AMBIENTES.each { envName ->
                        def sanFile = "${CERTS_DIR}/san-${envName}.cnf"
                        writeFile file: sanFile, text: """
[ req ]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[ req_distinguished_name ]
CN = *.sqfaas.dev

[ v3_req ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = *.sqfaas.dev
DNS.2 = ${envName}.sqfaas.dev
"""
                        echo "Arquivo san.cnf gerado: ${sanFile}"
                    }
                }
            }
        }

        stage('Criar ambientes e certificados') {
            steps {
                script {
                    TODOS_AMBIENTES.each { envName ->
                        echo "Criando/validando ambiente ${envName}"

                        // 1️⃣ Criar namespace e AppSet
                        sh "${ENVS_SCRIPTS}/create_env.sh ${envName} ${APPS_DIR}"

                        // 2️⃣ Criar secret acr-secret
                        sh "${ENVS_SCRIPTS}/create_registry_secret.sh ${envName}"

                        // 3️⃣ Configurar serviceaccount default para usar acr-secret
                        sh """
                        kubectl patch serviceaccount default -n ${envName} \
                          -p '{"imagePullSecrets": [{"name": "acr-secret"}]}'
                        """

                        // 4️⃣ Gerar certificados e criar secret sqfaas-files
                        def sanFile = "${CERTS_DIR}/san-${envName}.cnf"
                        sh "${ENVS_SCRIPTS}/create_certs.sh ${envName} ${sanFile} ${CERTS_DIR}"
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


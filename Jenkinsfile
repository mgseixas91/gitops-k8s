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

        stage('Preparar ambientes') {
            steps {
                script {
                    // Ambientes a criar
                    def AMBIENTES_A_CRIAR = ['tst0']
                    echo "Ambientes a criar: ${AMBIENTES_A_CRIAR}"

                    // Ambientes existentes no cluster
                    def EXISTENTES = sh(script: "kubectl get ns --no-headers -o custom-columns=:metadata.name | grep ^tst || true", returnStdout: true)
                                    .trim()
                                    .split("\n")
                                    .findAll { it }

                    echo "Ambientes existentes: ${EXISTENTES}"

                    // Todos ambientes que devem ter secret
                    TODOS_AMBIENTES = (AMBIENTES_A_CRIAR + EXISTENTES).unique()
                    echo "Todos ambientes para secret: ${TODOS_AMBIENTES.join(',')}"
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

                        // Criar namespace e AppSet
                        sh "${ENVS_SCRIPTS}/create_env.sh ${envName} ${APPS_DIR}"

                        // Criar secret acr-secret
                        sh "${ENVS_SCRIPTS}/create_registry_secret.sh ${envName}"

                        // Gerar certificados e criar secret sqfaas-files
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


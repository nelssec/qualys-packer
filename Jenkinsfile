pipeline {
    agent any

    parameters {
        choice(
            name: 'OS_TARGET',
            choices: ['amazon-linux-2023', 'ubuntu-2404'],
            description: 'OS target variable file'
        )
        choice(
            name: 'QUALYS_MODE',
            choices: ['get-report', 'evaluate-policy', 'scan-only', 'inventory-only'],
            description: 'QScanner scan mode'
        )
        string(
            name: 'QUALYS_POD',
            defaultValue: 'CA1',
            description: 'Qualys platform pod'
        )
        string(
            name: 'AWS_REGION',
            defaultValue: 'us-east-1',
            description: 'AWS region to build in'
        )
    }

    environment {
        QUALYS_ACCESS_TOKEN = credentials('qualys-access-token')
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_SESSION_TOKEN = credentials('aws-session-token')
        AWS_DEFAULT_REGION = "${params.AWS_REGION}"
    }

    stages {
        stage('Install Packer') {
            steps {
                sh '''
                    if ! command -v packer &> /dev/null; then
                        curl -sSfL https://releases.hashicorp.com/packer/1.11.2/packer_1.11.2_linux_amd64.zip -o /tmp/packer.zip
                        unzip -o /tmp/packer.zip -d /tmp/packer-bin/
                        rm /tmp/packer.zip
                    fi
                '''
            }
        }

        stage('Packer Init') {
            steps {
                sh 'export PATH="/tmp/packer-bin:$PATH" && packer init packer/'
            }
        }

        stage('Build Golden AMI') {
            steps {
                sh """
                    export PATH="/tmp/packer-bin:\$PATH"
                    packer build \
                        -var-file=packer/${params.OS_TARGET}.pkrvars.hcl \
                        -var "qualys_mode=${params.QUALYS_MODE}" \
                        -var "qualys_pod=${params.QUALYS_POD}" \
                        -var "region=${params.AWS_REGION}" \
                        -var "qscanner_s3_url=s3://qualys-qscanner-demo-314104994032/qscanner" \
                        packer/
                """
            }
        }
    }

    post {
        always {
            node('') {
                archiveArtifacts artifacts: 'output/**', allowEmptyArchive: true
            }
        }
        success {
            echo 'Golden AMI built and scanned successfully'
        }
        failure {
            echo 'Build failed - check QScanner results in archived artifacts'
        }
    }
}

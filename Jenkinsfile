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
            defaultValue: 'US1',
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
        AWS_DEFAULT_REGION = "${params.AWS_REGION}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Packer Init') {
            steps {
                sh 'packer init packer/'
            }
        }

        stage('Build Golden AMI') {
            steps {
                sh """
                    packer build \
                        -var-file=packer/${params.OS_TARGET}.pkrvars.hcl \
                        -var "qualys_mode=${params.QUALYS_MODE}" \
                        -var "qualys_pod=${params.QUALYS_POD}" \
                        -var "region=${params.AWS_REGION}" \
                        packer/
                """
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'output/**', allowEmptyArchive: true
        }
        success {
            echo 'Golden AMI built and scanned successfully'
        }
        failure {
            echo 'Build failed - check QScanner results in archived artifacts'
        }
    }
}

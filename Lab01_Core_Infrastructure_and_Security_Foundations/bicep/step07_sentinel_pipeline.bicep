// Bicep: Step 7 - Sentinel Pipeline and Threat Response
// Based on step07_sentinel_pipeline.md

param location string = resourceGroup().location
param vmName string = 'vm-jhost-neu01'
param logAnalyticsWorkspaceName string = 'log-sentinel-neu01'

// Log Analytics Workspace for Sentinel
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2025'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Enable Microsoft Sentinel on the Log Analytics Workspace
resource sentinelOnboarding 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'SecurityInsights(${logAnalyticsWorkspace.name})'
  location: location
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
  plan: {
    name: 'SecurityInsights(${logAnalyticsWorkspace.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/SecurityInsights'
    promotionCode: ''
  }
}

// Reference existing VM for diagnostic settings
resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  name: vmName
}

// Diagnostic Settings for VM - Send metrics to Log Analytics
resource vmDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'vm-to-sentinel'
  scope: vm
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
  }
}

// Azure Monitor Action Group for alert notifications
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'security-alerts-ag'
  location: 'global'
  properties: {
    groupShortName: 'SecAlerts'
    enabled: true
    emailReceivers: [
      {
        name: 'Personal_Email'
        emailAddress: 'pervazgolrang@protonmail.com'
        useCommonAlertSchema: true
      }
    ]
  }
}

// Sample Scheduled Query Rule for security monitoring
resource failedLoginAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'multiple-failed-logins'
  location: location
  properties: {
    displayName: 'Multiple Failed Login Attempts'
    description: 'Detects multiple failed login attempts'
    severity: 2
    enabled: true
    scopes: [
      logAnalyticsWorkspace.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT1H'
    criteria: {
      allOf: [
        {
          query: 'SigninLogs | where TimeGenerated > ago(1h) | where ResultType != "0" | summarize FailedAttempts = count() by IPAddress | where FailedAttempts >= 5'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }
  }
}

// Outputs
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name
output actionGroupId string = actionGroup.id

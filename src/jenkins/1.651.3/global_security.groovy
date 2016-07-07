import jenkins.model.*
import hudson.security.*

// Get access to the jenkins instance
def instance = Jenkins.getInstance()

// Activate global seufiry with internal hudsonRealm
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
instance.setSecurityRealm(hudsonRealm)

// Create an admin account
//hudsonRealm.createAccount("#{node['jenkins']['admin']['name']}", "#{node['jenkins']['admin']['password']}")
hudsonRealm.createAccount("toybox", "toybox")

// Activate matrix seurity and add admin user
def strategy = new GlobalMatrixAuthorizationStrategy()
strategy.add(Jenkins.ADMINISTER, "toybox")
instance.setAuthorizationStrategy(strategy)

instance.save()

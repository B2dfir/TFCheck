# TFCheck
A script to automate security and compliance checks of terraform projects

# How does it work?
TFcheck writes the output of the Terraform show command to config.out for parsing. 

When TFcheck parses config.out, it performs string manipulation to convert the config.out into compressed json format. From here TFcheck converts the Json string into Powershell objects using the ConvertFrom-Json function.

All configuration parameters are now nested Powershell objects, which are easy to reference and validate!

Simply write your rules within TFCheck.ps1 and then run it from within your Terraform project directory. Alternatively, you can automate it as a task in various development pipeline tools.

# Writing Rules

For some example rules to help get you started, please read the more detailed write-up on my blog
https://b2dfir.blogspot.com/2018/01/implementing-security-compliance-as.html



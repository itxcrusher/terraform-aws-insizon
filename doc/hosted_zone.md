# Hosted Zone



## Look into
1. https://www.youtube.com/watch?v=qZjpSfsJTW8







To connect a domain registered with Porkbun to AWS Route 53, you'll need to change the domain's nameservers at Porkbun to point to the Route 53 nameservers. You'll then configure a Hosted Zone in Route 53 for your domain. [1, 2]  
Here's a more detailed breakdown: 
1. Get Route 53 Nameservers: [3]  

• Log into the AWS Management Console and navigate to Route 53. [3]  
• Create a Hosted Zone for your domain in Route 53. [2]  
• Note down the NS (Nameserver) records provided by Route 53 for this Hosted Zone. [2]  

2. Change Nameservers at Porkbun: [4]  

• Log into your Porkbun account and navigate to the domain management section. 
• Locate the domain you want to manage with Route 53. 
• Edit the "Authoritative Nameservers" (NS) records. 
• Delete any existing nameserver entries. 
• Add the Route 53 nameservers you obtained in step 1, one per line. 
• Click "Submit" to save the changes. [4, 5]  

3. Verify and Manage in Route 53: [2]  

• Wait for the DNS propagation time (typically a few hours) for the changes at Porkbun to take effect. [2]  
• In Route 53, you can now add your A, MX, and TXT records for your domain to manage your DNS settings. [6]  

Generative AI is experimental.

[1] https://kb.porkbun.com/article/54-pointing-your-domain-to-hosting-with-a-records[2] https://dev.to/mubbashir10/point-your-domain-to-aws-using-route-53-42kf[3] https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/GetInfoAboutHostedZone.html[4] https://kb.porkbun.com/article/22-how-to-change-nameservers[5] https://www.youtube.com/watch?v=WTDLwMqslQ0[6] https://serverfault.com/questions/1159819/dns-route53-porkbun-oh-my



To manage a subdomain and use AWS Route 53 with a domain registered at Porkbun, you'll need to create a new hosted zone for the subdomain in Route 53 and then update the NS records of the domain at Porkbun to point to Route 53's nameservers. This allows Route 53 to manage the DNS for the subdomain while the parent domain remains registered at Porkbun. [1, 2]  
Here's a more detailed breakdown: 
1. Create a Hosted Zone in Route 53: [3]  

• Log in to the AWS Management Console and navigate to Route 53. 
• Select "Hosted zones" and then "Create hosted zone". 
• Enter the subdomain you want to manage (e.g., sub.example.com). 
• Choose "Public hosted zone" and click "Create hosted zone". [3]  

2. Obtain Route 53 Nameservers: [2]  

• After creating the hosted zone, Route 53 will provide a set of nameservers (NS records). [2]  

3. Update NS Records at Porkbun: [2]  

• Log in to your Porkbun account and navigate to the domain management page. 
• Locate your domain and click the details button. 
• Find the NS records and replace them with the nameservers you got from Route 53. [2, 4]  

4. Configure DNS Records in Route 53: [1, 5]  

• Now, you can manage DNS records for your subdomain within Route 53's hosted zone. 
• This includes creating A records, CNAME records, MX records, and other DNS records needed for your website or applications. [1, 5]  

Generative AI is experimental.

[1] https://serverfault.com/questions/1159819/dns-route53-porkbun-oh-my[2] https://dev.to/mubbashir10/point-your-domain-to-aws-using-route-53-42kf[3] https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-routing-traffic-for-subdomains.html[4] https://kb.porkbun.com/article/54-pointing-your-domain-to-hosting-with-a-records[5] https://kb.porkbun.com/article/231-how-to-add-dns-records-on-porkbun
Not all images can be exported from Search.

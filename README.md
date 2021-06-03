# LucidHomework

### Time Limit
As per instructions, all code was written within a 2 hour timeframe, although I did return later to fix an issue.

### Summary
This IaC consists of:
1. A single VPC split into 3-tier architecture.
2. An ALB + ASG + Launch Template for hosting the web application.
3. An Aurora Serverless Postgres (RDS) cluster for the DB.
4. Appropriate SGs for allowing port 80 to the ALB, port 80 from the ALB to the ASG, and all traffic between the ASG and RDS.

*Side Note: I've forgotten how the VPC module that I used handles SG creation/modification. So I may need to check that the VPC-wide traffic is properly controlled too.*

### Functionality of Code
I didn't deploy this code. However, I did run a `terraform plan` and the plan was clean. As with all "clean" plans, it's still possible that I might encoutner errors during deployment.
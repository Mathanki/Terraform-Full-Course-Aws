

# Day 15: VPC & Peering On AWS with Terraform (Mini Project 2) | #30DaysOfAWSTerraform

In today’s cloud architectures, it’s common for applications to span multiple VPCs, regions, and even AWS accounts. As these environments grow, connecting networks securely and efficiently becomes one of the most important design considerations.

In this blog, we will walk through **VPC Peering**, how it enables private communication between VPCs, and why it’s a powerful but limited connectivity option—especially when networks scale. More importantly, we’ll explore the concept of **transitive connectivity**, why it matters in multi-VPC and multi-region setups, and how AWS **Transit Gateway** plays a key role in solving challenges that VPC Peering alone cannot address.

## VPC Peering

In this mini-project, the goal is to understand how **AWS VPC Peering** works across **multiple regions**. The demo creates two VPCs—one in **us-east-1** and the other in **us-west-2**—and establishes a **VPC Peering Connection** between them.

This allows EC2 instances in both VPCs to communicate privately using **private IP addresses**, without going over the public internet.

![](day-15-vpc/9efadd62-451f-4e5f-ad06-90d41460aefc.png)

This project provisions **two independent VPCs** deployed across **two AWS regions**, each using **non-overlapping CIDR ranges** to ensure seamless routing and inter-VPC communication.

### Primary VPC (us-east-1)**

-   **CIDR Block:** `10.0.0.0/16`
    
-   **Public Subnet:** `10.0.1.0/24`
    
-   **Internet Gateway:** Attached for outbound traffic
    
-   **Route Table:**
    
    -   Local VPC routing
        
    -   `0.0.0.0/0` → Internet Gateway
        
    -   Peering route to secondary VPC
        
-   **EC2 Instance:**
    
    -   Amazon Linux 2
        
    -   Apache Web Server installed
        
-   **Security Group Rules:**
    
    -   Allow **SSH (22)** from own public IP
        
    -   Allow **HTTP (80)** inbound
        
    -   Allow **inter-VPC private traffic** from `10.1.0.0/16`
        

### **Secondary VPC (us-west-2)**

-   **CIDR Block:** `10.1.0.0/16`
    
-   **Public Subnet:** `10.1.1.0/24`
    
-   **Internet Gateway:** Attached
    
-   **Route Table:**
    
    -   Local VPC routing
        
    -   `0.0.0.0/0` → Internet Gateway
        
    -   Peering route to primary VPC
        
-   **EC2 Instance:**
    
    -   Amazon Linux 2
        
    -   Apache Web Server installed
        
-   **Security Group Rules:**
    
    -   Allow **SSH (22)** from own public IP
        
    -   Allow **HTTP (80)** inbound
        
    -   Allow **inter-VPC private traffic** from `10.0.0.0/16`
        

## Configuring Multi-Region AWS Providers

When deploying infrastructure across different AWS regions, Terraform requires multiple provider configurations. Each provider is tied to a specific region, making sure resources land where they are intended.

This setup typically includes:

-   A **primary provider** (e.g., us-east-1)
    
-   A **secondary provider** with an alias (e.g., us-west-2)
    

Using aliased providers keeps the configuration organized and ensures that VPCs, EC2 instances, and networking components are provisioned in the correct region without code duplication.

```
# Provider for the primary region (us-east-1)
provider "aws" {
  region = var.primary_region
  alias  = "primary"
}

# Provider for the secondary region (us-west-2)
provider "aws" {
  region = var.secondary_region
  alias  = "secondary"
}
```

## Establishing Cross-Region VPC Peering

To enable private communication between workloads running in different regions, a **VPC peering connection** is created between two VPCs.

Highlights of this implementation:

-   The VPC in the primary region initiates the peering request.
    
-   The VPC in the secondary region accepts the request using its aliased provider.
    
-   Unique, non-overlapping CIDR blocks ensure compatibility.
    
-   Once active, the peering connection acts as a secure, private bridge between regions.
    

This enables seamless communication without using public IPs or internet gateways.

```
# VPC Peering Connection (Requester side - Primary VPC)
resource "aws_vpc_peering_connection" "primary_to_secondary" {
  provider    = aws.primary
  vpc_id      = aws_vpc.primary_vpc.id
  peer_vpc_id = aws_vpc.secondary_vpc.id
  # Note: You MUST specify the peer region for cross-region peering
  peer_region = var.secondary_region
  auto_accept = false

  tags = {
    Name        = "Primary-to-Secondary-Peering"
    Side        = "Requester"
  }
}

# VPC Peering Connection Accepter (Accepter side - Secondary VPC)
resource "aws_vpc_peering_connection_accepter" "secondary_accepter" {
  provider                  = aws.secondary
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id
  # By setting auto_accept = true, the accepter immediately accepts the connection request
  auto_accept               = true
  tags = {
    Name = "Secondary-Peering-Accepter"
    Side = "Accepter"
  }
}
```

## Enabling Traffic Flow with Route Tables

A peering connection alone doesn't allow traffic to flow—you must update route tables in both VPCs.

Each VPC contains:

-   A public subnet with an internet route
    
-   A route table associated with that subnet
    
-   Additional routes added for VPC-to-VPC communication
    

To fully enable cross-region connectivity:

-   The **primary VPC's route table** includes a route pointing to the secondary VPC's CIDR via the peering connection.
    
-   The **secondary VPC's route table** mirrors this in the opposite direction.
    

These bidirectional routes enable EC2 instances to communicate using private IP addresses, completing the networking path.

```
# Add route to Secondary VPC in Primary route table
resource "aws_route" "primary_to_secondary" {
  provider                  = aws.primary
  route_table_id            = aws_route_table.primary_rt.id
  destination_cidr_block    = var.secondary_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id

  depends_on = [aws_vpc_peering_connection_accepter.secondary_accepter]
}

# Add route to Primary VPC in Secondary route table
resource "aws_route" "secondary_to_primary" {
  provider                  = aws.secondary
  route_table_id            = aws_route_table.secondary_rt.id
  destination_cidr_block    = var.primary_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id

  depends_on = [aws_vpc_peering_connection_accepter.secondary_accepter]
}
```

## Designing Security Groups for Inter-VPC Access

Security groups must be configured to explicitly allow the traffic you expect between regions.

Each EC2 instance's security group includes:

-   **SSH access (port 22)** for administrative access
    
-   **HTTP access (port 80)** for Apache web server traffic
    
-   **Inbound rules** allowing communication from the other VPC’s CIDR range
    

This ensures only necessary traffic is allowed while maintaining security best practices.

A well-designed security group:

-   Allows cross-region communication
    
-   Restricts unwanted traffic
    
-   Supports secure access to each instance
    

```
 ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP from Secondary VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.secondary_vpc_cidr]
  }

  ingress {
    description = "All traffic from Secondary VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.secondary_vpc_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
```

## **Testing Connectivity**

**Test private connectivity** between instances:

**Pinging From Primary VPC → Secondary VPC:**

![](day-15-vpc/068696f6-b30a-480b-9e1e-6386fadbb1de.png)

-   The EC2 instance in the **Primary VPC (us-east-1)** can successfully reach the EC2 instance in the **Secondary VPC (us-west-2)**.
    
-   ICMP packets travel across the VPC Peering connection without any issue.
    
-   Route tables correctly point traffic to the peering connection.
    
-   Security groups on the target instance allow **ICMP** from the peer VPC CIDR.
    

**Pinging From Secondary VPC → Primary VPC :**

![](day-15-vpc/ba6d163c-9fec-414e-9fb1-28aa892a3c44.png)

-   The EC2 instance in **Secondary VPC (us-west-2)** can reach the instance in the **Primary VPC (us-east-1)** using private networking.
    
-   This proves **bidirectional connectivity**, meaning the peering setup is functioning end-to-end.
    
-   Security groups and network ACLs allow ICMP traffic.
    

**Perform** `curl` **commands from one instance to another using private IP addresses:**

From Primary VPC → Secondary VPC :

![](day-15-vpc/af580cf8-d9b0-461e-a963-d616d40550d8.png)

-   The EC2 instance in the **primary VPC (us-east-1)** can successfully reach the **secondary EC2 instance** in **us-west-2** on private IP `10.1.1.9`.
    
-   The Apache server on the secondary instance returns:
    
    -   It’s the **Secondary VPC Instance**
        
    -   Region tag: **us-west-2**
        
    -   Its private IP
        

From Secondary VPC → Primary VPC:

![](day-15-vpc/b744085d-9251-4971-af37-c1fd066e9d58.png)

-   The EC2 instance in the **secondary VPC (us-west-2)** is successfully reaching the **primary EC2 instance** in **us-east-1** using its private IP `10.0.1.82`.
    
-   The Apache server running on the primary instance returns an HTML response confirming:
    
    -   It’s the **Primary VPC Instance**
        
    -   Region tag: **us-east-1**
        
    -   Its private IP
        

## Limitations of VPC Peering (Especially in Multi-Region)

While VPC Peering is a simple and effective way to connect two VPCs, it also comes with several limitations—especially when working across multiple AWS regions. However, as organizations scale their infrastructure across multiple environments and regions, VPC peering's simplicity quickly gives way to complexity. For large, multi-region deployments, VPC peering introduces several limitations that can become major architectural headaches.

1.  Non-Transitive Connectivity
    
    If VPC A is peered with VPC B, And VPC B is peered with VPC C so VPC A cannot communicate with VPC C unless VPC A and VPC C have their own direct peering connection
    
    In multi-region setups, this leads to complex network topologies and rapid expansion of peering links.
    
2.  No Centralized Network Hub
    
    Multi-region architectures often need a hub-and-spoke model for shared services (DNS, security appliances, logging, etc.). VPC Peering cannot act as a hub
    
3.  Limited Multi-Region Capabilities
    
    Although VPC Peering supports cross-region connections, it has limitations:
    
    -   Cross-region peering does not support IPv6 peering in some regions.
        
    -   Higher latency due to inter-region travel.
        
    -   Higher cost compared to same-region peering (charged per GB for data transfer).
        
    -   No consolidated routing or network orchestration.
        
4.  Manual Route Table Management
    
    For each VPC you peer, you must:
    
    -   Manually add routes in every involved route table.
        
    -   Maintain these routes whenever subnets or CIDRs change.
        
    -   Ensure no overlap between VPC CIDR blocks.
        

In dynamic or large environments, this results in operational overhead and more chances of misconfiguration.

5.  No Shared Security or Network Policies
    
    VPC Peering does not allow:
    
    -   Centralized firewall appliances
        
    -   Shared NAT
        
    -   Central inspection layers
        
    -   Traffic monitoring across VPCs
        

Every VPC must configure and manage its own security groups, NACLs, NAT gateways, and monitoring tools.

6.  Cannot Be Used for Overlapping CIDR Blocks
    
    VPC Peering requires non-overlapping CIDRs between VPCs.
    
    In multi-region environments—especially large enterprises—CIDR conflicts become common.
    
7.  Limited to Unicast Traffic (No Multicast/Broadcast)
    
    VPC Peering supports only unicast traffic.
    
    Multi-region architectures requiring multicast for distributed systems or real-time applications cannot rely on peering.
    

## AWS Transit Gateway (TGW): The Scalable Solution

![](day-15-vpc/3c78b42c-5183-4670-b595-b6e493a6dfe2.png)

AWS Transit Gateway acts as a regional network hub.

Think of it as a cloud router that connects VPCs and on-prem networks easily.

Here’s how Transit Gateway overcomes the pain points of VPC Peering:

1.  Centralized Hub-and-Spoke Architecture
    
    Transit Gateway acts as a central network hub where multiple VPCs and on-premises networks connect.
    
    -   No full-mesh peering required
        
    -   No route table explosion
        
    -   Easy to add/remove VPCs without reconfiguring others
        

TGW simplifies multi-region and multi-account network topologies dramatically.

2.  Supports Transitive Routing
    
    Unlike VPC Peering, TGW allows transitive routing:
    
    -   VPC A → TGW → VPC B
        
    -   VPC B → TGW → On-prem
        
    -   VPC A → TGW → VPC C
        

This eliminates the need for separate connections between each pair of VPCs.

Traffic can move through the Transit Gateway intelligently and securely.

3.  Simplified Route Tables
    
    Transit Gateway maintains its own central route tables.
    
    -   VPCs only need a single route pointing to TGW
        
    -   No need to update every route table manually
        
    -   Easy to visualize and manage with TGW route table views
        

This reduces operational overhead and prevents misconfigurations.

## Conclusion

This project successfully demonstrated the power of multi-region networking built on Infrastructure as Code (IaC) principles. By utilizing **VPC Peering**, we established secure, low-latency connectivity between disparate AWS regions without ever exposing traffic to the public internet, a critical requirement for high-performance and compliance-focused applications.

The comprehensive **Terraform implementation** ensures that every component—from VPCs and subnets to route tables and security groups—is reproducible, auditable, and version-controlled, providing a stable foundation for deployment.

Furthermore, while this setup is ideal for two-region connectivity, it serves as the necessary stepping stone for more complex, large-scale architectures that would use **Transit Gateway Peering** to create centralized, transitive network hubs for connecting dozens of VPCs globally. Ultimately, this base architecture supports essential capabilities like **disaster recovery**, **geo-redundancy**, and globally distributed application deployments, paving the way for truly resilient and scalable cloud operations.

## Reference

https://www.youtube.com/watch?v=WGt000THDmQ&list=PLl4APkPHzsUXcfBSJDExYR-a4fQiZGmMp&index=17

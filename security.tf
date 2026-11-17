# --- ALB security group: open to the internet on port 80 ---
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Allow HTTP from the internet to the ALB"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "alb-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# --- App security group: only accepts traffic from the ALB ---
resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "Allow HTTP only from the ALB"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "app-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# --- DB security group: only accepts PostgreSQL from the app servers ---
resource "aws_security_group" "db" {
  name        = "db-sg"
  description = "Allow PostgreSQL only from the app tier"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "db-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}
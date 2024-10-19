
resource "aws_db_subnet_group" "main" {
  name       = "${var.name}-${var.env}"
  subnet_ids = var.subnets

  tags = merge(var.tags,{"Name"="${var.name}-${var.env}-sng"})
}

resource "aws_security_group" "main" {
  name        = "${var.name}-${var.env}-sg"
  description = "${var.name}-${var.env}-sg"
  vpc_id      = var.vpc_id

  ingress {
    description = "RDS"
    from_port   = var.port_no
    to_port     = var.port_no
    protocol    = "tcp"
    cidr_blocks = var.allow_db_cidr

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = merge(var.tags,{"Name"="${var.name}-${var.env}-sg"})
}



resource "aws_db_parameter_group" "main" {
  name   = "${var.name}-${var.env}-pg"
  family = "aurora-mysql5.7"
  tags = merge(var.tags,{"Name"="${var.name}-${var.env}-pg"})


}
resource "aws_rds_cluster" "main" {
  cluster_identifier      = "aurora-cluster-demo"
  engine                  = "aurora-mysql"
  engine_version          = var.engine_version
  database_name           = "dummy"
  master_username         = data.aws_ssm_parameter.db_user.value
  master_password         = data.aws_ssm_parameter.db_pass.value
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  vpc_security_group_ids = [aws_security_group.main.id]
  db_subnet_group_name = aws_db_subnet_group.main.name
  db_cluster_parameter_group_name = aws_db_parameter_group.main.name
  kms_key_id = var.kms_arn
  port = var.port_no
  skip_final_snapshot = true
  storage_encrypted = true
  tags = merge(var.tags,{"Name"="${var.name}-${var.env}-rds"})

}


resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = var.instance_count
  identifier         = "aurora-cluster-demo-${count.index}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version
  tags = merge(var.tags,{"Name"="${var.name}-${var.env}-rds-${count.index+1}"})

}
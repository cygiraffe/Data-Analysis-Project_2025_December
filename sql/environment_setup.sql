create database DA_Project_No1;
use DA_Project_No1;

/*
테이블 만들 때 들어가는 자료형들
문자열
ENUM
date
정수
소수
Boolean
*/
/*
enum으로 들어갈 것들
accounts 테이블: referral_source, plan_tier
subscriptions 테이블: plan_tier, billing_frequency
churned 테이블: reason

*/
# generate accounts table
create table accounts (
    account_id varchar(50) primary key,
    account_name varchar(50),
    industry enum('Cybersecurity','DevTools','EdTech','FinTech','HealthTech'),
    country varchar(10),
    signup_date DATE,
    referral_source Enum('partner', 'ads', 'organic', 'event', 'other'),
    plan_tier Enum('Basic','Enterprise','Pro'),
    seats int,
    is_trial boolean,
    churned boolean
);

#generate subscriptions table
create table subscriptions (
    subscription_id varchar(50) primary key,
    account_id varchar(50),
    start_date date,
    end_date date null,
    plan_tier enum('Basic','Enterprise','Pro'),
    seats int,
    mrr_amount int,
    arr_amount int,
    is_trial boolean,
    upgraded boolean,
    downgraded boolean,
    churned boolean,
    billing_frequency enum('monthly','annual'),
    auto_renewed boolean,
    # foreign key configuration
    foreign key (account_id) references accounts(account_id)
);
# DROP TABLE subscriptions;

#generate churns table
create table churns(
    churn_id varchar(50) primary key,
    account_id varchar(50),
    churn_date date,
    reason Enum('pricing', 'support', 'budget', 'features', 'competitor', 'unknown'),
    refund decimal(10,2),
    preceding_upgrade boolean,
    preceding_downgrade boolean,
    reactivated boolean,
    feedback_text varchar(255),
    # foreign key configuration
    foreign key (account_id) references accounts(account_id)
);

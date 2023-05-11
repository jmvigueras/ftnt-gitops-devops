# Vulnerable-Flask-App
Based on -> Erlik 2 - Vulnerable-Flask-App

## Description
It is a vulnerable Flask Web App. It is a lab environment created for people who want to improve themselves in the field of web penetration testing.

## Features

It contains the following vulnerabilities.

- HTML Injection
- XSS
- SSTI
- SQL Injection
- Information Disclosure
- Command Injection
- Brute Force
- Deserialization
- Broken Authentication
- DOS
- File Upload

## Installation
git clone https://github.com/jmvigueras/vuln-flask-app
cd vuln-flask-app
sudo pip3 install -r requirements.txt

## Example of SQL injection
curl "http://<api-end-point>/user/test'%20OR%201=1%20--"


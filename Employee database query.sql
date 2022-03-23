--- Querying sample employee database.
--- SELECT, WHERE, HAVING, GROUP BY, ORDER BY.
--- UPDATE, INSERT, DROP, DELETE
--- SUM, AVG, COUNT
---LIMIT
--- JOINS
    
SELECT 
    *
FROM
    employees
WHERE
    first_name = 'Kellie' AND gender = 'F';
    
Select * from employees
Where first_name = 'Kellie' OR first_name = 'Aruna';

Select * from employees
Where gender = 'F' AND (first_name = 'Kellie' OR first_name = 'Aruna');

Use employees;

Select * from employees
Where first_name IN ('Denis','Elvis');

Select * from employees
Where first_name NOT IN ('John','Mark','Jacob');

Select * from employees
Where first_name LIKE ('Mark%');

Select * from employees
Where hire_date >= '2000-01-01';

Select * from employees
Where emp_no LIKE ('1000_');

Select * from employees
Where hire_date LIKE ('%2000%');

Select * from salaries
Where salary BETWEEN 66000 AND 70000;

Select * from employees
Where emp_no NOT BETWEEN 10004 AND 10012;

Use employees;

Select DISTINCT hire_date from employees
LIMIT 1000;

Select COUNT(DISTINCT first_name) from employees;

Select COUNT(salary) from salaries
Where salary >= 100000;

Select COUNT(*) from dept_manager;

Select * from employees
Order by hire_date DESC;

Select salary, COUNT(salary) AS emps_with_same_salary
from salaries
Where salary > 80000
Group by Salary
Order by Salary;

Use employees;

Select *, AVG(Salary) from salaries
Where salary > 120000
Group by emp_no
Order by emp_no; 

Select emp_no, avg(Salary) As Avg_Salary from salaries
group by emp_no
Having AVG(Salary) > 120000
Order by emp_no;

Select emp_no from dept_emp
Where from_date > '2000-01-01'
Group by emp_no
Having COUNT(from_date) > 1
Order by emp_no;

SELECT 
    *
FROM
    salaries
ORDER BY Salary DESC
LIMIT 10;

Select * from dept_emp
LIMIT 100;

--- [Insert Statements]

Insert into employees
Values
(
	999903,
    '1977-09-14',
    'Jonathan',
    'Creek',
    'M',
    '1999-01-01'
);

Select * from employees
Order by emp_no DESC;

Select * from titles
Limit 10;

Insert into titles
(
	emp_no,
    title,
    from_date
)

Values

(
	999903,
	'Senior Engineer',
    '1997-10-01',
    'null'
);

insert into titles
(
    emp_no,

    title,

    from_date

)

values

(
	 999903,
	'Senior Engineer',
	'1997-10-01'
);

Select * from dept_emp
Limit 10;

Insert into dept_emp

Values
(
	999903,
    'd005',
    '1997-10-01',
    '9999-01-01' 
);

Select * from dept_emp
Order by emp_no DESC
LIMIT 10;

Select * from departments;

Create table departments_dup
(
	dept_no CHAR(4) NOT NULL,
    dept_name VARCHAR(40) Not null
);

Select * from departments_dup;

Insert into departments_dup
(
	dept_no,
    dept_name
    
)
Select * from departments
Order by dept_no;

Select * from departments;
Use employees;

Insert into departments
Values
(
	'd010',
    'Business Analysis'
);

Use employees;

Select * from employees;

Select * from employees
where emp_no = 999901;

Insert INTO Employees
Values
(
	999901,
    '1986-04-21',
    'John',
    'Smith',
    'M',
    '2011-01-01'
);

Update employees
SET
	first_name = 'Stella',
    last_name = 'Parkinson',
    birth_date = '1990-12-31',
    gender = 'F',
    hire_date = '2011-01-01'
Where
	emp_no = 999901;
    
Select * from employees
Where emp_no = 999901;

Select * from departments_dup
order by dept_no;

COMMIT;

Update departments_dup
SET 
	dept_no = 'd011',
    dept_name = 'Quality Control';
    
select * from departments;

Update departments
SET
	dept_name = 'Data Analysis'
Where
	dept_no = 'd010';
    
COMMIT;

Select * from employees
Where emp_no = 999903;

Delete FROM employees
Where emp_no = 999903;

COMMIT;

Use employees;

Select * from dept_emp;

Select COUNT(DISTINCT dept_no) from dept_emp;

Select * from salaries;
Select SUM(salary) from salaries
Where from_date > '1997-01-01';

Select * from employees;

Select MIN(emp_no) from employees;
Select MAX(emp_no) from employees;

Select AVG(salary) from salaries
Where from_date > '1997-01-01';

Select ROUND(AVG(Salary),2) From salaries
where from_date > '1997-01-01';

Select * from departments_dup;

Alter table departments_dup
ALTER column dept_no dept_no CHAR(4) NULL;

Alter table departments_dup
ALTER column dept_name dept_name VARCHAR(40) NULL;

Select * from departments_dup;

DROP TABLE IF EXISTS departments_dup;

CREATE TABLE departments_dup

(
    dept_no CHAR(4) NULL,

    dept_name VARCHAR(40) NULL

);

INSERT INTO departments_dup

(
    dept_no,

    dept_name
)

SELECT
                *
FROM
                departments;

INSERT INTO departments_dup (dept_name)

VALUES         
		('Public Relations');


DELETE FROM departments_dup

WHERE

    dept_no = 'd002';
	
INSERT INTO departments_dup(dept_no) 
VALUES
		('d010'), 
		('d011');

Select * from departments_dup;

ALTER table departments_dup
ALTER column dept_no dept_no CHAR(4) NULL;

Use employees;

DROP TABLE IF EXISTS dept_manager_dup;

CREATE TABLE dept_manager_dup (

  emp_no int(11) NOT NULL,

  dept_no char(4) NULL,

  from_date date NOT NULL,

  to_date date NULL

  );

--Creating duplicate table and inserting values from existing table

INSERT INTO dept_manager_dup

select * from dept_manager;

INSERT INTO dept_manager_dup 
			(emp_no, from_date)

VALUES              
		(999904, '2017-01-01'),

        (999905, '2017-01-01'),

        (999906, '2017-01-01'),

        (999907, '2017-01-01');

 
DELETE FROM dept_manager_dup

WHERE

    dept_no = 'd001';

INSERT INTO departments_dup (dept_name)

VALUES                
	
		('Public Relations');

DELETE FROM departments_dup

WHERE

    dept_no = 'd002'; 
    
--------------

--JOINS 

Select * from employees, dept_manager;

Select 
		e.emp_no,
		e.first_name, 
		e.last_name, 
		d.dept_no, 
		d.from_date

FROM employees e
LEFT JOIN
dept_manager d ON e.emp_no = d.emp_no
Where e.last_name = 'Markovitch'
Order by d.dept_no DESC, e.emp_no;

Select 
		e.emp_no, 
		e.first_name, 
		e.last_name, 
		d.dept_no, 
		d.from_date
From
	employees e,
    dept_manager d
Where
	e.emp_no = d.emp_no

Order by
		e.emp_no,
		d.dept_no;

Use employees;

Select * from employees, salaries;

Select 
		e.gender, 
		AVG(Salary) As Avg_Salary
From 
	employees e
JOIN
salaries s ON e.emp_no = s.emp_no
group by e.gender;

COMMIT;

---Multiple tables joining

SELECT
    e.first_name,
    e.last_name,
    e.hire_date,
    t.title,
    m.from_date,
    d.dept_name
FROM
    employees e
        JOIN
    dept_manager m ON e.emp_no = m.emp_no

        JOIN

    departments d ON m.dept_no = d.dept_no
        JOIN

    titles t ON e.emp_no = t.emp_no

WHERE t.title = 'Manager'

ORDER BY e.emp_no;

Select * from employees, titles;

Select 
		e.gender, 
		COUNT(t.title) As Managers
From 
	employees e
	JOIN
titles t ON e.emp_no = t.emp_no

Where title = 'Manager'

group by e.gender;

Select 
		e.first_name, 
		e.last_name, 
		t.title

From 
	employees e

INNER JOIN

titles t ON e.emp_no = t.emp_no

Group by title;






    










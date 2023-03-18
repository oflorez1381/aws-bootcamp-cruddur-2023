# Week 4 — Postgres and RDS

During week 04, we did the follow activities:

| Activities                                                      | Youtube                                        | Link                                                              | Status |
|-----------------------------------------------------------------|------------------------------------------------|-------------------------------------------------------------------| -- |
| Watched Ashish's Week 4 - Security Considerations               | https://www.youtube.com/watch?v=UourWxz7iQg&list=PLBfufR7vyJJ7k25byhRXJldB5AiwgNnWv&index=45 | |✅|
| Create RDS Postgres Instance                                    | https://www.youtube.com/watch?v=EtD7Kv5YCUs&list=PLBfufR7vyJJ7k25byhRXJldB5AiwgNnWv&index=46 | |✅|
| Bash scripting for common database actions                      | https://www.youtube.com/watch?v=EtD7Kv5YCUs&list=PLBfufR7vyJJ7k25byhRXJldB5AiwgNnWv&index=46 | |✅|
| Install Postgres Driver in Backend Application                  | https://www.youtube.com/watch?v=Sa2iB33sKFo&list=PLBfufR7vyJJ7k25byhRXJldB5AiwgNnWv&index=47 | |✅|
| Connect Gitpod to RDS Instance                                  | https://www.youtube.com/watch?v=Sa2iB33sKFo&list=PLBfufR7vyJJ7k25byhRXJldB5AiwgNnWv&index=47 | |✅|
| Create Cognito Trigger to insert user into database             | https://www.youtube.com/watch?v=7qP4RcY2MwU&list=PLBfufR7vyJJ7k25byhRXJldB5AiwgNnWv&index=48 | |✅|
| Create new activities with a database insert                    | https://www.youtube.com/watch?v=fTksxEQExL4&list=PLBfufR7vyJJ7k25byhRXJldB5AiwgNnWv&index=49 | |✅|

## Shell Script to Connect to DB

For things we commonly need to do we can create a new directory called `bin`

We'll create an new folder called `bin` to hold all our bash scripts.

```sh
mkdir /workspace/aws-bootcamp-cruddur-2023/backend-flask/bin
```

```sh
export CONNECTION_URL="postgresql://postgres:pssword@127.0.0.1:5433/cruddur"
gp env CONNECTION_URL="postgresql://postgres:pssword@127.0.0.1:5433/cruddur"
```

## Shell script to connect the database
`bin/db-connect`

```sh
#! /usr/bin/bash
if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL
```

We'll make it executable:

```sh
chmod u+x bin/db-connect
```

To execute the script:
```sh
./bin/db-connect
```

## Shell script to drop the database

`bin/db-drop`

```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-drop"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "drop database cruddur;"
```

https://askubuntu.com/questions/595269/use-sed-on-a-string-variable-rather-than-a-file

## See what connections we are using

`bin/db-sessions`

```sh
#! /usr/bin/bash
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-sessions"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

NO_DB_URL=$(sed 's/\/cruddur//g' <<<"$URL")
psql $NO_DB_URL -c "select pid as process_id, \
       usename as user,  \
       datname as db, \
       client_addr, \
       application_name as app,\
       state \
from pg_stat_activity;"
```

## Shell script to create the database

`bin/db-create`

```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-create"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "create database cruddur;"
```

## Shell script to load the schema

`bin/db-schema-load`

```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-schema-load"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

schema_path="$(realpath .)/db/schema.sql"
echo $schema_path

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL cruddur < $schema_path
```

## Shell script to load the seed data

`bin/db-seed`

```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-seed"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

seed_path="$(realpath .)/db/seed.sql"
echo $seed_path

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL cruddur < $seed_path
```

## Easily setup (reset) everything for our database


```sh
#! /usr/bin/bash
-e # stop if it fails at any point

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-setup"
printf "${CYAN}==== ${LABEL}${NO_COLOR}\n"

bin_path="$(realpath .)/bin"

source "$bin_path/db-drop"
source "$bin_path/db-create"
source "$bin_path/db-schema-load"
source "$bin_path/db-seed"
```

## Make prints nicer

We can make prints for our shell scripts coloured so we can see what we're doing:

https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux


```sh
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-schema-load"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"
```

## Install Postgres Client

We need to set the env var for our backend-flask application:

```yml
  backend-flask:
    environment:
      CONNECTION_URL: "${CONNECTION_URL}"
```

https://www.psycopg.org/psycopg3/

We'll add the following to our `requirements.txt`

```
psycopg[binary]
psycopg[pool]
```

```sh
pip install -r requirements.txt
```

## DB Object and Connection Pool


`lib/db.py`

```py
from psycopg_pool import ConnectionPool
import os

def query_wrap_object(template):
  sql = '''
  (SELECT COALESCE(row_to_json(object_row),'{}'::json) FROM (
  {template}
  ) object_row);
  '''

def query_wrap_array(template):
  sql = '''
  (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
  {template}
  ) array_row);
  '''

connection_url = os.getenv("CONNECTION_URL")
pool = ConnectionPool(connection_url)
```

In our home activities we'll replace our mock endpoint with real api call:

```py
from lib.db import pool, query_wrap_array

      sql = query_wrap_array("""
      SELECT
        activities.uuid,
        users.display_name,
        users.handle,
        activities.message,
        activities.replies_count,
        activities.reposts_count,
        activities.likes_count,
        activities.reply_to_activity_uuid,
        activities.expires_at,
        activities.created_at
      FROM public.activities
      LEFT JOIN public.users ON users.uuid = activities.user_uuid
      ORDER BY activities.created_at DESC
      """)
      print(sql)
      with pool.connection() as conn:
        with conn.cursor() as cur:
          cur.execute(sql)
          # this will return a tuple
          # the first field being the data
          json = cur.fetchone()
      return json[0]
```

## Provision RDS Instance

```sh
aws rds create-db-instance \
  --db-instance-identifier cruddur-db-instance \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version  14.6 \
  --master-username root \
  --master-user-password xxxxxxxxxxxxx \
  --allocated-storage 20 \
  --availability-zone ca-central-1a \
  --backup-retention-period 0 \
  --port 5432 \
  --no-multi-az \
  --db-name cruddur \
  --storage-type gp2 \
  --publicly-accessible \
  --storage-encrypted \
  --enable-performance-insights \
  --performance-insights-retention-period 7 \
  --no-deletion-protection
```
## Connect to RDS via Gitpod

In order to connect to the RDS instance we need to provide our Gitpod IP and whitelist for inbound traffic on port 5432.

```sh
GITPOD_IP=$(curl ifconfig.me)
```

We'll create an inbound rule for Postgres (5432) and provide the GITPOD ID.
<img src="assets/week4/01-inbound.png" width="1000"/>

Whenever we need to update our security groups we can do this for access.
```sh
aws ec2 modify-security-group-rules \
    --group-id $DB_SG_ID \
    --security-group-rules "SecurityGroupRuleId=$DB_SG_RULE_ID,SecurityGroupRule={IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32}"
```

## Setup Cognito post confirmation lambda

### Create the handler function

#### Create lambda in same vpc as rds instance Python 3.8
  <img src="assets/week4/01-lambda.png" width="1000"/>
<img src="assets/week4/02-lambda.png" width="1000"/>
<img src="assets/week4/03-lambda.png" width="1000"/>
<img src="assets/week4/04-lambda.png" width="1000"/>

```python
  def lambda_handler(event, context):
  user = event['request']['userAttributes']
  print('userAttributes')
  print(user)

  user_display_name  = user['name']
  user_email         = user['email']
  user_handle        = user['preferred_username']
  user_cognito_id    = user['sub']
  try:
  print('entered-try')
  sql = f"""
  INSERT INTO public.users (
  display_name,
  email,
  handle,
  cognito_user_id
  )
  VALUES(
  '{user_display_name}',
  '{user_email}',
  '{user_handle}',
  '{user_cognito_id}'
  )
  """
  print('SQL Statement ----')
  print(sql)
  conn = psycopg2.connect(os.getenv('CONNECTION_URL'))
  cur = conn.cursor()
  cur.execute(sql)
  conn.commit()

  except (Exception, psycopg2.DatabaseError) as error:
  print(error)
  finally:
  if conn is not None:
  cur.close()
  conn.close()
  print('Database connection closed.')
  return event
```
<img src="assets/week4/06-lambda.png" width="1000"/>
<img src="assets/week4/05-lambda.png" width="1000"/>

#### Add a layer for psycopg2 with one of the below methods for development or production

<img src="assets/week4/07-lambda.png" width="1000"/>
<img src="assets/week4/08-lambda.png" width="1000"/>
<img src="assets/week4/09-lambda.png" width="1000"/>
<img src="assets/week4/10-lambda.png" width="1000"/>

#### Add the function to Cognito 
<img src="assets/week4/11-lambda.png" width="1000"/>
<img src="assets/week4/12-lambda.png" width="1000"/>
<img src="assets/week4/13-lambda.png" width="1000"/>
<img src="assets/week4/14-lambda.png" width="1000"/>
<img src="assets/week4/15-lambda.png" width="1000"/>
<img src="assets/week4/16-lambda.png" width="1000"/>
<img src="assets/week4/17-lambda.png" width="1000"/>
<img src="assets/week4/18-lambda.png" width="1000"/>
<img src="assets/week4/19-lambda.png" width="1000"/>
<img src="assets/week4/20-lambda.png" width="1000"/>
<img src="assets/week4/21-lambda.png" width="1000"/>
<img src="assets/week4/22-lambda.png" width="1000"/>

### Setup Production DB
<img src="assets/week4/23-lambda.png" width="1000"/>
<img src="assets/week4/24-lambda.png" width="1000"/>
 
### Test UI with Backend
<img src="assets/week4/25-lambda.png" width="1000"/>
<img src="assets/week4/26-lambda.png" width="1000"/>
<img src="assets/week4/27-lambda.png" width="1000"/>
<img src="assets/week4/28-lambda.png" width="1000"/>
<img src="assets/week4/29-lambda.png" width="1000"/>
<img src="assets/week4/30-lambda.png" width="1000"/>
<img src="assets/week4/31-lambda.png" width="1000"/>

### Create new activities
<img src="assets/week4/01-activity.png" width="1000"/>
<img src="assets/week4/02-activity.png" width="1000"/>
<img src="assets/week4/03-activity.png" width="1000"/>

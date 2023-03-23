-- this file was manually created
INSERT INTO public.users (display_name, email, handle, cognito_user_id)
VALUES
    ('Oscar Florez','oscarflorez1381@gmail.com' , 'oflorez' ,'MOCK'),
    ('Oscar Dario Florez Diaz','oscar_florez1381@hotmail.com' , 'odfd' ,'MOCK');
    ('Londo Mollari','lmollari@centari.com' ,'londo' ,'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
    (
        (SELECT uuid from public.users WHERE users.handle = 'oflorez' LIMIT 1),
    'This was imported as seed data!',
                current_timestamp + interval '10 day'
    )
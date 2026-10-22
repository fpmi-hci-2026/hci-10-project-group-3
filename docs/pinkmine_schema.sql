-- Pinkmine: структура БД (PostgreSQL)
CREATE SCHEMA pinkmine;

-- 1. Справочники
CREATE TABLE pinkmine.roles (
    id   smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code text NOT NULL UNIQUE CHECK (code ~ '^[a-z_]+$'),
    name text NOT NULL CHECK (btrim(name) <> '')
);

CREATE TABLE pinkmine.permissions (
    id          smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code        text NOT NULL UNIQUE CHECK (code ~ '^[a-z_.]+$'),
    description text
);

CREATE TABLE pinkmine.role_permissions (
    role_id       smallint NOT NULL REFERENCES pinkmine.roles (id) ON DELETE CASCADE,
    permission_id smallint NOT NULL REFERENCES pinkmine.permissions (id) ON DELETE RESTRICT,
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE pinkmine.task_statuses (
    id           smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code         text NOT NULL UNIQUE CHECK (code ~ '^[a-z_]+$'),
    name         text NOT NULL CHECK (btrim(name) <> ''),
    sort_order   smallint NOT NULL UNIQUE,
    is_completed boolean NOT NULL
);

CREATE TABLE pinkmine.task_types (
    id   smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code text NOT NULL UNIQUE CHECK (code ~ '^[a-z_]+$'),
    name text NOT NULL CHECK (btrim(name) <> '')
);

-- 2. Пользователи
CREATE TABLE pinkmine.users (
    id                 bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    login              text NOT NULL CHECK (btrim(login) <> ''),
    email              text NOT NULL CHECK (position('@' IN email) > 1),
    password_hash      text NOT NULL,
    first_name         text NOT NULL CHECK (btrim(first_name) <> ''),
    last_name          text NOT NULL CHECK (btrim(last_name) <> ''),
    role_id            smallint NOT NULL REFERENCES pinkmine.roles (id) ON DELETE RESTRICT,
    email_confirmed_at timestamptz,
    created_at         timestamptz NOT NULL DEFAULT now(),
    updated_at         timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE pinkmine.user_tokens (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id    bigint NOT NULL REFERENCES pinkmine.users (id) ON DELETE CASCADE,
    purpose    text NOT NULL CHECK (purpose IN ('email_confirmation', 'password_reset')),
    token_hash text NOT NULL UNIQUE,
    created_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz NOT NULL,
    used_at    timestamptz,
    CHECK (expires_at > created_at)
);

CREATE TABLE pinkmine.device_tokens (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id      bigint NOT NULL REFERENCES pinkmine.users (id) ON DELETE CASCADE,
    platform     text NOT NULL CHECK (platform IN ('android')),
    token        text NOT NULL UNIQUE,
    created_at   timestamptz NOT NULL DEFAULT now(),
    last_seen_at timestamptz NOT NULL DEFAULT now()
);

-- 3. Проекты и команда
CREATE TABLE pinkmine.workspaces (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       text NOT NULL CHECK (btrim(name) <> ''),
    owner_id   bigint NOT NULL REFERENCES pinkmine.users (id) ON DELETE RESTRICT,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE pinkmine.projects (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    workspace_id bigint NOT NULL REFERENCES pinkmine.workspaces (id) ON DELETE RESTRICT,
    name         text NOT NULL CHECK (btrim(name) <> ''),
    description  text,
    created_by   bigint NOT NULL REFERENCES pinkmine.users (id) ON DELETE RESTRICT,
    created_at   timestamptz NOT NULL DEFAULT now(),
    archived_at  timestamptz
);

CREATE TABLE pinkmine.project_members (
    project_id bigint NOT NULL REFERENCES pinkmine.projects (id) ON DELETE CASCADE,
    user_id    bigint NOT NULL REFERENCES pinkmine.users (id) ON DELETE RESTRICT,
    role_id    smallint NOT NULL REFERENCES pinkmine.roles (id) ON DELETE RESTRICT,
    joined_at  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (project_id, user_id)
);

CREATE TABLE pinkmine.invitations (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    project_id  bigint NOT NULL REFERENCES pinkmine.projects (id) ON DELETE CASCADE,
    email       text NOT NULL CHECK (position('@' IN email) > 1),
    role_id     smallint NOT NULL REFERENCES pinkmine.roles (id) ON DELETE RESTRICT,
    token_hash  text NOT NULL UNIQUE,
    invited_by  bigint NOT NULL REFERENCES pinkmine.users (id) ON DELETE RESTRICT,
    created_at  timestamptz NOT NULL DEFAULT now(),
    expires_at  timestamptz NOT NULL,
    accepted_at timestamptz,
    accepted_by bigint REFERENCES pinkmine.users (id) ON DELETE RESTRICT,
    revoked_at  timestamptz,
    CHECK (expires_at > created_at),
    CHECK ((accepted_at IS NULL) = (accepted_by IS NULL)),
    CHECK (accepted_at IS NULL OR revoked_at IS NULL)
);

-- 4. Задачи
CREATE TABLE pinkmine.tasks (
    id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    project_id          bigint NOT NULL REFERENCES pinkmine.projects (id) ON DELETE CASCADE,
    title               text NOT NULL CHECK (btrim(title) <> ''),
    description         text,
    status_id           smallint NOT NULL REFERENCES pinkmine.task_statuses (id) ON DELETE RESTRICT,
    type_id             smallint NOT NULL REFERENCES pinkmine.task_types (id) ON DELETE RESTRICT,
    author_id           bigint NOT NULL REFERENCES pinkmine.users (id) ON DELETE RESTRICT,
    assignee_user_id    bigint,
    due_date            date,
    overdue_notified_at timestamptz,
    version             integer NOT NULL DEFAULT 1 CHECK (version > 0),
    created_at          timestamptz NOT NULL DEFAULT now(),
    updated_at          timestamptz NOT NULL DEFAULT now(),
    UNIQUE (project_id, id),
    -- NO ACTION: проверка в конце оператора, каскадное удаление проекта не блокируется
    FOREIGN KEY (project_id, assignee_user_id)
        REFERENCES pinkmine.project_members (project_id, user_id) ON DELETE NO ACTION
);

CREATE TABLE pinkmine.tags (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    project_id bigint NOT NULL REFERENCES pinkmine.projects (id) ON DELETE CASCADE,
    name       text NOT NULL CHECK (btrim(name) <> ''),
    color      text NOT NULL CHECK (color ~ '^#[0-9A-Fa-f]{6}$'),
    UNIQUE (project_id, id)
);

CREATE TABLE pinkmine.task_tags (
    project_id bigint NOT NULL,
    task_id    bigint NOT NULL,
    tag_id     bigint NOT NULL,
    PRIMARY KEY (task_id, tag_id),
    FOREIGN KEY (project_id, task_id) REFERENCES pinkmine.tasks (project_id, id) ON DELETE CASCADE,
    FOREIGN KEY (project_id, tag_id) REFERENCES pinkmine.tags (project_id, id) ON DELETE CASCADE
);

CREATE TABLE pinkmine.comments (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_id    bigint NOT NULL REFERENCES pinkmine.tasks (id) ON DELETE CASCADE,
    author_id  bigint NOT NULL REFERENCES pinkmine.users (id) ON DELETE RESTRICT,
    body       text NOT NULL CHECK (btrim(body) <> ''),
    created_at timestamptz NOT NULL DEFAULT now(),
    edited_at  timestamptz,
    CHECK (edited_at IS NULL OR edited_at >= created_at)
);

CREATE TABLE pinkmine.attachments (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_id      bigint NOT NULL REFERENCES pinkmine.tasks (id) ON DELETE CASCADE,
    author_id    bigint NOT NULL REFERENCES pinkmine.users (id) ON DELETE RESTRICT,
    file_name    text NOT NULL CHECK (btrim(file_name) <> ''),
    content_type text NOT NULL,
    size_bytes   bigint NOT NULL CHECK (size_bytes > 0),
    storage_key  text NOT NULL UNIQUE,
    created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE pinkmine.task_history (
    id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_id           bigint NOT NULL REFERENCES pinkmine.tasks (id) ON DELETE CASCADE,
    task_version      integer NOT NULL CHECK (task_version > 0),
    author_id         bigint NOT NULL REFERENCES pinkmine.users (id) ON DELETE RESTRICT,
    field             text NOT NULL CHECK (field IN ('title', 'description', 'status', 'type', 'assignee', 'due_date')),
    old_value         text,
    new_value         text,
    reason_comment_id bigint REFERENCES pinkmine.comments (id) ON DELETE SET NULL,
    created_at        timestamptz NOT NULL DEFAULT now(),
    UNIQUE (task_id, task_version, field)
);

-- 5. Уведомления
CREATE TABLE pinkmine.notifications (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    recipient_id    bigint NOT NULL REFERENCES pinkmine.users (id) ON DELETE CASCADE,
    task_id         bigint REFERENCES pinkmine.tasks (id) ON DELETE SET NULL,
    event_type      text NOT NULL CHECK (event_type IN (
                        'member_invited', 'member_added', 'task_assigned', 'task_status_changed',
                        'task_deadline_changed', 'task_overdue', 'comment_added', 'overdue_digest')),
    channel         text NOT NULL CHECK (channel IN ('push', 'email', 'in_app')),
    body            text NOT NULL CHECK (btrim(body) <> ''),
    delivery_status text NOT NULL DEFAULT 'pending' CHECK (delivery_status IN ('pending', 'sent', 'failed')),
    attempts        smallint NOT NULL DEFAULT 0 CHECK (attempts >= 0),
    last_error      text,
    created_at      timestamptz NOT NULL DEFAULT now(),
    sent_at         timestamptz,
    read_at         timestamptz
);

-- 6. Индексы
CREATE UNIQUE INDEX users_login_lower_uq ON pinkmine.users (lower(login));
CREATE UNIQUE INDEX users_email_lower_uq ON pinkmine.users (lower(email));
CREATE INDEX users_role_idx ON pinkmine.users (role_id);
CREATE INDEX user_tokens_user_idx ON pinkmine.user_tokens (user_id);
CREATE INDEX device_tokens_user_idx ON pinkmine.device_tokens (user_id);
CREATE INDEX workspaces_owner_idx ON pinkmine.workspaces (owner_id);
CREATE INDEX projects_workspace_idx ON pinkmine.projects (workspace_id);
CREATE INDEX projects_created_by_idx ON pinkmine.projects (created_by);
CREATE INDEX project_members_user_idx ON pinkmine.project_members (user_id);
CREATE INDEX project_members_role_idx ON pinkmine.project_members (role_id);
CREATE INDEX invitations_project_idx ON pinkmine.invitations (project_id);
CREATE UNIQUE INDEX invitations_active_email_uq ON pinkmine.invitations (project_id, lower(email))
    WHERE accepted_at IS NULL AND revoked_at IS NULL;
CREATE INDEX invitations_role_idx ON pinkmine.invitations (role_id);
CREATE INDEX invitations_invited_by_idx ON pinkmine.invitations (invited_by);
CREATE INDEX invitations_accepted_by_idx ON pinkmine.invitations (accepted_by) WHERE accepted_by IS NOT NULL;
CREATE INDEX tasks_project_status_idx ON pinkmine.tasks (project_id, status_id, due_date, id);
CREATE INDEX tasks_assignee_idx ON pinkmine.tasks (assignee_user_id, project_id) WHERE assignee_user_id IS NOT NULL;
CREATE INDEX tasks_author_idx ON pinkmine.tasks (author_id);
CREATE INDEX tasks_overdue_check_idx ON pinkmine.tasks (due_date)
    WHERE due_date IS NOT NULL AND overdue_notified_at IS NULL;
CREATE UNIQUE INDEX tags_project_name_uq ON pinkmine.tags (project_id, lower(name));
CREATE INDEX task_tags_tag_idx ON pinkmine.task_tags (project_id, tag_id);
CREATE INDEX comments_task_idx ON pinkmine.comments (task_id, created_at, id);
CREATE INDEX comments_author_idx ON pinkmine.comments (author_id);
CREATE INDEX attachments_task_idx ON pinkmine.attachments (task_id);
CREATE INDEX attachments_author_idx ON pinkmine.attachments (author_id);
CREATE INDEX task_history_author_idx ON pinkmine.task_history (author_id);
CREATE INDEX task_history_reason_comment_idx ON pinkmine.task_history (reason_comment_id)
    WHERE reason_comment_id IS NOT NULL;
CREATE INDEX notifications_recipient_idx ON pinkmine.notifications (recipient_id, created_at DESC, id DESC);
CREATE INDEX notifications_unread_idx ON pinkmine.notifications (recipient_id) WHERE read_at IS NULL;
CREATE INDEX notifications_task_idx ON pinkmine.notifications (task_id) WHERE task_id IS NOT NULL;
CREATE INDEX notifications_pending_idx ON pinkmine.notifications (created_at) WHERE delivery_status = 'pending';

-- 7. Комментарии к неочевидным объектам
COMMENT ON COLUMN pinkmine.tasks.version IS 'Версия для оптимистической блокировки; увеличивается при каждом изменении задачи';
COMMENT ON COLUMN pinkmine.tasks.overdue_notified_at IS 'Когда отправлено напоминание о просрочке; сбрасывается при переносе срока';
COMMENT ON COLUMN pinkmine.task_history.task_version IS 'Версия задачи после изменения; защищает от дублей при повторной синхронизации';
COMMENT ON COLUMN pinkmine.invitations.token_hash IS 'Хеш токена ссылки; сам токен в БД не хранится';

--8. Справочники ролей, прав, статусов и типов
INSERT INTO pinkmine.roles (code, name) VALUES
    ('admin', 'Администратор системы'), ('manager', 'Менеджер проекта'), ('member', 'Участник команды');

INSERT INTO pinkmine.permissions (code, description) VALUES
    ('project.create', 'Создавать проекты'), ('project.archive', 'Архивировать проект'),
    ('project.delete', 'Физически удалять проект'), ('member.add', 'Добавлять и приглашать участников'),
    ('member.remove', 'Исключать участников'), ('task.create', 'Создавать задачи'),
    ('task.assign', 'Назначать исполнителя и менять тип'), ('task.set_due_date', 'Устанавливать и переносить срок'),
    ('task.change_status', 'Менять статус задачи'), ('task.review', 'Принимать и возвращать на доработку'),
    ('task.close', 'Закрывать задачу'), ('comment.create', 'Комментировать и прикреплять файлы'),
    ('role.manage', 'Настраивать права ролей');

INSERT INTO pinkmine.role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM pinkmine.roles r JOIN pinkmine.permissions p ON
       (r.code = 'member'  AND p.code IN ('task.create', 'task.change_status', 'comment.create'))
    OR (r.code = 'manager' AND p.code IN ('task.create', 'task.change_status', 'comment.create', 'project.create',
                                          'project.archive', 'member.add', 'member.remove', 'task.assign',
                                          'task.set_due_date', 'task.review', 'task.close'))
    OR (r.code = 'admin');

INSERT INTO pinkmine.task_statuses (code, name, sort_order, is_completed) VALUES
    ('new', 'Новая', 1, false), ('in_progress', 'В работе', 2, false), ('review', 'На проверке', 3, false),
    ('postponed', 'Отложена', 4, false), ('done', 'Готова', 5, true), ('closed', 'Закрыта', 6, true);

INSERT INTO pinkmine.task_types (code, name) VALUES
    ('task', 'Задача'), ('bug', 'Ошибка'), ('improvement', 'Улучшение'), ('idea', 'Идея'), ('meeting', 'Встреча');
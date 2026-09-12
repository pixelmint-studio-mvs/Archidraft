export type Bindings = {
  DB: D1Database;
};

export type Variables = {
  user: {
    uid: string;
    role: string;
  };
};

export type AppEnv = {
  Bindings: Bindings;
  Variables: Variables;
};

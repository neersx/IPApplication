namespace InprotechKaizen.Model.Persistence
{
    public static class SysObjects
    {
        public static readonly string Function = "'FN'";
        public static readonly string View = "'V'";
        public static readonly string Table = "'U'";
        public static readonly string StoredProcedure = "'P'";
    }

    public interface IDbArtifacts
    {
       bool Exists(string name, params string[] sysObjects);
    }
}

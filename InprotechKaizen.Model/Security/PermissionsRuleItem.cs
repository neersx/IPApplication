namespace InprotechKaizen.Model.Security
{
    public class PermissionsRuleItem
    {
        public int? ObjectIntegerKey { get; set; }

        public int LevelKey { get; set; }

        public string ObjectStringKey { get; set; }

        public byte? SelectPermission { get; set; }

        public byte? MandatoryPermission { get; set; }

        public byte? InsertPermission { get; set; }

        public byte? UpdatePermission { get; set; }

        public byte? DeletePermission { get; set; }

        public byte? ExecutePermission { get; set; }
    }

    public class Permissions
    {
        public byte GrantPermission { get; set; }
        public byte DenyPermission { get; set; }
    }

    public class FakePermissionsSet : PermissionsRuleItem
    {
        public byte GrantPermission { get; set; }
        public byte DenyPermission { get; set; }
        public string ObjectTable { get; set; }
        public string LevelTable { get; set; }
    }
}
namespace Inprotech.Web.Picklists
{
    public class PicklistModel<T>
    {
        public PicklistModel()
        {
        }

        public PicklistModel(T key, string code, string value)
        {
            Key = key;
            Code = code;
            Value = value;
        }

        public T Key { get; set; }

        public string Code { get; set; }

        public string Value { get; set; }
    }
    
    public static class PicklistModelHelper
    {
        public static PicklistModel<T> GetPicklistOrNull<T>(T? key, string code, string value) where T : struct
        {
            return key == null ? null : new PicklistModel<T>(key.Value, code, value);
        }

        public static PicklistModel<T> GetPicklistOrNull<T>(T? key, string value) where T : struct
        {
            return GetPicklistOrNull(key, null, value);
        }

        public static PicklistModel<T> GetPicklistOrNull<T>(T key, string code, string value) where T : class
        {
            return key == null ? null : new PicklistModel<T>(key, code, value);
        }

        public static PicklistModel<T> GetPicklistOrNull<T>(T key, string value) where T : class
        {
            return GetPicklistOrNull(key, null, value);
        }
    }
}
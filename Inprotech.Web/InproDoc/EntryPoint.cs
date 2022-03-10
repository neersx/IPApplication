
namespace Inprotech.Web.InproDoc
{
    public enum EntryPointValueType
    {
        String = 0,
        Integer = 1,
        Date = 2,
        ZeroPaddedString = 3
    }

    public class EntryPoint
    {
        public string Name { get; set; }
        public string Description { get; set; }
        public string AskLabel { get; set; }
        public EntryPointValueType EntryPointValueType { get; set; }
        public int? Length { get; set; }
        public bool RequireValidation { get; set; }
        public string ItemValidation { get; set; }
        public string Value { get; set; }
        public bool EvalItemOnRegister { get; set; }
    }
}

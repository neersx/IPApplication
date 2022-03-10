
namespace InprotechKaizen.Model.Components.Names
{
    public class DuplicateName
    {
        public string Id { get; set; }

        public string Name { get; set; }

        public string GivenName { get; set; }

        public short? UsedAs { get; set; }

        public bool Allow { get; set; }

        public string PostalAddress { get; set; }

        public string StreetAddress { get; set; }

        public string City { get; set; }

        public int? UsedAsOwner { get; set; }

        public int? UsedAsInstructor { get; set; }

        public int? UsedAsDebtor { get; set; }

        public string MainContact { get; set; }

        public string Telephone { get; set; }

        public string WebSite { get; set; }

        public string Fax { get; set; }

        public string Email { get; set; }

        public string Remarks { get; set; }

        public string SearchKey1 { get; set; }

        public string SearchKey2 { get; set; }
    }
}

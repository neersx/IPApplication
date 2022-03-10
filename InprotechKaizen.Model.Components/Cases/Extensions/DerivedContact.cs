using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Components.Cases.Extensions
{
    public class DerivedContact
    {
        public DerivedContact(Name name, Address address)
        {
            Name = name;
            Address = address;
        }

        public Address Address { get; private set; }
        public Name Name { get; private set; }
    }
}
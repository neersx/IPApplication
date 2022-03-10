using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Web.Builders.Model.Names
{
    public class AddressBuilder : IBuilder<Address>
    {
        public int? AddressCode { get; set; }

        public string Street1 { get; set; }

        public string City { get; set; }

        public string PostCode { get; set; }

        public Country Country { get; set; }

        public string State { get; set; }

        public Address Build()
        {
            return new Address(AddressCode ?? Fixture.Integer())
            {
                Street1 = Street1,
                City = City,
                PostCode = PostCode,
                Country = Country ?? new CountryBuilder().Build(),
                State = State
            };
        }
    }
}
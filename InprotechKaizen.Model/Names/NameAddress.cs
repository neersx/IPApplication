using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Configuration;

namespace InprotechKaizen.Model.Names
{
    [Table("NAMEADDRESS")]
    public class NameAddress
    {
        [Obsolete("For persistence only.")]
        public NameAddress()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public NameAddress(Name name, Address address, TableCode addressTypeTableCode)
        {
            if (name == null) throw new ArgumentNullException("name");
            if (address == null) throw new ArgumentNullException("address");
            if (addressTypeTableCode == null) throw new ArgumentNullException("addressTypeTableCode");

            NameId = name.Id;
            Name = name;

            Address = address;
            AddressId = address.Id;
            AddressTypeTableCode = addressTypeTableCode;
        }

        [Key]
        [Column("NAMENO", Order = 0)]
        public int NameId { get; set; }

        [Key]
        [Column("ADDRESSTYPE", Order = 1)]
        public int AddressType { get; set; }

        [Key]
        [Column("ADDRESSCODE", Order = 2)]
        public int AddressId { get; set; }

        public int? AddressStatus { get; set; }

        [Column("DATECEASED")]
        public DateTime? DateCeased { get; set; }

        [Column("OWNEDBY")]
        public decimal? OwnedBy { get; set; }

        public virtual Name Name { get; protected set; }

        public virtual TableCode AddressTypeTableCode { get; protected set; }

        public virtual Address Address { get; set; }

        public virtual TableCode AddressStatusTableCode { get; set; }
    }
}
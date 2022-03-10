using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Configuration;

namespace InprotechKaizen.Model.Names
{
    [Table("NAMEADDRESSCPACLIENT")]
    public class NameAddressCpaClient
    {
        [Obsolete("For persistence only.")]
        public NameAddressCpaClient()
        {
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public NameAddressCpaClient(Name name, Address address, TableCode addressTypeTableCode)
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

        [Key]
        [MaxLength(2)]
        [Column("ALIASTYPE", Order = 3)]
        public string Aliastype { get; set; }

        [Column("CPACLIENTNO")]
        public int CpaClientNo { get; set; }

        [ForeignKey("NameId")]
        public virtual Name Name { get; protected set; }

        [ForeignKey("AddressType")]
        public virtual TableCode AddressTypeTableCode { get; protected set; }

        [ForeignKey("AddressId")]
        public virtual Address Address { get; protected set; }
    }
}

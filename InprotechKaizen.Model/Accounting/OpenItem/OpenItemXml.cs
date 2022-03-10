using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.OpenItem
{
    [Table("OPENITEMXML")]
    public class OpenItemXml
    {
        [Key]
        [Column("ITEMENTITYNO", Order = 1)]
        public int ItemEntityId { get; set; }

        [Key]
        [Column("ITEMTRANSNO", Order = 2)]
        public int ItemTransactionId { get; set; }

        [Key]
        [Column("XMLTYPE", Order = 3)]
        public OpenItemXmlType XmlType { get; set; }

        [Column("OPENITEMXML")]
        public string OpenItemXmlValue { get; set; }
    }
}

using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede
{
    [Table("EDEREQUESTTYPE")]
    public class EdeRequestType
    {
        [Key]
        [MaxLength(50)]
        [Column("REQUESTTYPECODE")]
        public string RequestTypeCode { get; set; }
    }
}

using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Billing
{
    [Table("BILLFORMAT")]
    public class BillFormat
    {
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("BILLFORMATID")]
        public short BillFormatId { get; set; }

        [Column("NAMENO")]
        public int? NameId { get; set; }
    }
}
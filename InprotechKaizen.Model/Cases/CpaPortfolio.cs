using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("CPAPORTFOLIO")]
    public class CpaPortfolio
    {
        public CpaPortfolio()
        {
        }

        public CpaPortfolio(Case @case, DateTime dateOfPortfolioList, string statusIndicator)
        {
            if(@case == null) throw new ArgumentNullException(nameof(@case));

            CaseId = @case.Id;
            DateOfPortfolioList = dateOfPortfolioList;
            StatusIndicator = statusIndicator;
        }

        [Key]
        [Column("PORTFOLIONO")]
        [Required]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int Id { get; set; }

        [Column("DATEOFPORTFOLIOLST")]
        public DateTime? DateOfPortfolioList { get; set; }

        [Column("STATUSINDICATOR", TypeName = "nchar")]
        [StringLength(1, MinimumLength = 1)]
        public string StatusIndicator { get; set; }

        [Column("CASEID")]
        public int? CaseId { get; set; }

        [Column("RESPONSIBLEPARTY", TypeName = "nchar")]
        [StringLength(1, MinimumLength = 1)]
        public string ResponsibleParty { get; set; }

        [MaxLength(7)]
        [Column("IPRURN")]
        public string IprUrn { get; set; }
    }
}
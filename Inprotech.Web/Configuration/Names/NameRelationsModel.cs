using System.ComponentModel.DataAnnotations;

namespace Inprotech.Web.Configuration.Names
{
    public class NameRelationsModel
    {
        public int Id { get; set; }

        [Required]
        public string RelationshipCode { get; set; }

        [Required]
        public string RelationshipDescription { get; set; }

        [Required]
        public string ReverseDescription { get; set; }

        public bool IsIndividual { get; set; }
        public bool IsEmployee { get; set; }
        public bool IsOrganisation { get; set; }
        public bool? IsCrmOnly { get; set; }
        public bool HasCrmLisences { get; set; }
        public string EthicalWall { get; set; }
        public string EthicalWallValue { get; set; }
    }
}

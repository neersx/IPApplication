namespace Inprotech.Infrastructure.ThirdPartyLicensing
{
    public interface IThirdPartyLicensing
    {
        void Configure();
    }

    public class ThirdPartyLicensing : IThirdPartyLicensing
    {
        const string AsposePdfLicensePath = "Aspose.Pdf.lic";
        const string AsposeWordLicensePath = "Aspose.Words.lic";
        const string AsposeCellsLicensePath = "Aspose.Cells.lic";

        public void Configure()
        {
            var pdfLicense = new Aspose.Pdf.License();
            pdfLicense.SetLicense(AsposePdfLicensePath);

            var wordLicense = new Aspose.Words.License();
            wordLicense.SetLicense(AsposeWordLicensePath);

            var cellsLicensePath = new Aspose.Cells.License();
            cellsLicensePath.SetLicense(AsposeCellsLicensePath);
        }
    }
}

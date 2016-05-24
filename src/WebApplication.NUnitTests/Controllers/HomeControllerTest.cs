using NUnit.Framework;

namespace WebApplication.Controllers
{
    [TestFixture]
    public class HomeControllerTest
    {
        [Test]
        public void About_WhenCalled_ShouldFillInTheMessage()
        {
            var sut = new HomeController();

            sut.About();

            Assert.IsNotEmpty(sut.ViewBag.Message);
        }
    }
}
import { Contract, Interface, Signer, parseEther } from "ethers";
import { ethers } from "hardhat";
import { NodeOperator,Proxy } from "../typechain";
const { expect } = require("chai");
describe("registration test", function () {
    let owner: Signer, rollupAdmin: Signer, user1: Signer;
    let nodeOperator: NodeOperator, nodeOperatorImplementation: Interface, nodeOperatorProxy:Proxy;
    before(async function () {
        [owner, rollupAdmin, user1] = await ethers.getSigners();
        const NodeOperatorImpl = await ethers.getContractFactory("NodeOperator");
        nodeOperatorImplementation = NodeOperatorImpl.interface;
        const nodeImp = await NodeOperatorImpl.deploy();
        console.log("node operator implementation deployed:", await nodeImp.getAddress());
        const NodeOperatorProxy = await ethers.getContractFactory("Proxy");
        nodeOperatorProxy = await NodeOperatorProxy.deploy(
          nodeOperatorImplementation.encodeFunctionData("initialize", []),
          await nodeImp.getAddress()
        );
        console.log("node operator proxy deployed:", await nodeOperatorProxy.getAddress());

        nodeOperator =await NodeOperatorImpl.attach(await nodeOperatorProxy.getAddress());
    })
    it("should register SSV node Operator", async function () {
        await nodeOperator.registerSSVOperator(1,"LS0tLS1CRUdJTiBSU0EgUFVCTElDIEtFWS0tLS0tCk1JSUJJakFOQmdrcWhraUc5dzBCQVFFRkFBT0NBUThBTUlJQkNnS0NBUUVBdmo5UmpQTFk5YXd1WVc3NVRVcVoKVWozRWRMN2NkdDFnUjlydHowQU02TENNbTdCNG5DcW1RYjRCeFBsUktVeVl1ZnNEbXIzeTVqUmdVbHBHR0ZRawpOWmU0VGRZQkxPNnRUZ1NyMXphMUlGR0R2dzdJUUJZSHoramFEYVN6Zk9vYnNiUldiMDVaZFdGc01keGlEam5vCnR2NHZ4eGpCOWlXa2xmaytUNXB4K3ZwTWZnd1M2Ui9EOU84Y0dZdTg1b0RpQXgzQ0tPampuY3BPV0pndHhxZUMKbENDbldxSS9PeTFSa1FVcFNYL1hsRHozSHhCN0NlY0IzeUUwNnNTbXd1WTZHdk9tMUEvMmdNVUprbDFTUmFjbgpDeFhYK1hVWWFEemZGdXBBeWxPVnIxMEFnUkpTcVd2SkoxcnJCZkFwSzBMNzFMQzFzVzRyWjloMGFIN2pweW1aCjF3SURBUUFCCi0tLS0tRU5EIFJTQSBQVUJMSUMgS0VZLS0tLS0K","http://123.5.5.1:3000","nexus");
        await nodeOperator.registerSSVOperator(2,"LS0tLS1CRUdJTiBSU0EgUFVCTElDIEtFWS0tLS0tCk1JSUJJakFOQmdrcWhraUc5dzBCQVFFRkFBT0NBUThBTUlJQkNnS0NBUUVBN0hvU2s2ZTNkY1RVZ2M0V2phaDQKcDdRblFmdnB5c3d0ZU5jVldKNC9ONW1mRVFqY285ZFhqdy92Y3crbDdDVXZIVWdNNVI2STg1WXBOdC9ON2pjUApOR2oyNW9KR2hmb2dmMytLNzVKdVlod01BMnpreXZaREl3NE5HdTdBYkFrdkROcFk0emVQZjdnalhpV0hWczFxCllqVWY5MUVxUTg3ZjBkZ2lPeVNBcFNCbzVvNGc0eTVodUs5blBDeUlka0tieTJaWVRnd3p5Tm1KWnd2cUhKSk0KN2hhUFdXTkpSQjMyeGlSTWRHL2JYcnNVL1Rodm5acWxybTVGdENVckpCcXNPaXlZTGs4WGdOZ1pMdzJZcHNQTwpxeWV4bHdvNXcvczk5Sm41a3dQMkdUeTczVnErOVV0TE5SZ3NPdmkweUZObFhTaURJeEdCV0YrTU1pRjZVWmk3CnBRSURBUUFCCi0tLS0tRU5EIFJTQSBQVUJMSUMgS0VZLS0tLS0K","http://123.5.7.1:3000","nexus_2");
        await expect(nodeOperator.connect(user1).registerSSVOperator(3,"LS0tLS1CRUdJTiBSU0EgUFVCTElDIEtFWS0tLS0tCk1JSUJJVEFOQmdrcWhraUc5dzBCQVFFRkFBT0NBUTRBTUlJQkNRS0NBUUJ3amhORXpBLzB4R1lXRDFHRzhWZnAKL01nN0NibVRHNE12alZpaUtzWTNtTnZ1VzZlMWJ6T3JpL2cvRHh3TkpOZmppQlBoRytYb095UnozU2IzWDV5TApMbEhBWXpGbzBaTGd5SFlmaDZ6SG5JTG5rSEYxVXc5aG96REhxcGtUUlZTa1M4YUxFbmxPdnNIRFJZMXExUTlOCm15MGxTODM5eUV4WFN4WWMrNDJDNDVLWUFzWnhFTHpNUm1PYjMzUklqSitNUStTaFhBMC9ZY2xKOEpIWDgvVGkKb3dsMzRpNDIwZVpwV2dBZGFpdElFQzhucjEzeitWeWFINk5QZExYZ0wxdnFnWXpLbFU2aEIwcGwrc3NyWFFuZApiVkNnelZ0alpzeG9ic3A4ZVJqb3hYVzdDeFBmNnlEN09JbnUvUHF2eHd3QXFWb0Rqb3UvSlYySnIzTE5ZODVsCkFnTUJBQUU9Ci0tLS0tRU5EIFJTQSBQVUJMSUMgS0VZLS0tLS0K","http://123.51.7.1:3000","nexus_3")).to.be.revertedWithCustomError(nodeOperator,"NotOwner");
        await expect(nodeOperator.registerSSVOperator(2,"LS0tLS1CRUdJTiBSU0EgUFVCTElDIEtFWS0tLS0tCk1JSUJJakFOQmdrcWhraUc5dzBCQVFFRkFBT0NBUThBTUlJQkNnS0NBUUVBN0hvU2s2ZTNkY1RVZ2M0V2phaDQKcDdRblFmdnB5c3d0ZU5jVldKNC9ONW1mRVFqY285ZFhqdy92Y3crbDdDVXZIVWdNNVI2STg1WXBOdC9ON2pjUApOR2oyNW9KR2hmb2dmMytLNzVKdVlod01BMnpreXZaREl3NE5HdTdBYkFrdkROcFk0emVQZjdnalhpV0hWczFxCllqVWY5MUVxUTg3ZjBkZ2lPeVNBcFNCbzVvNGc0eTVodUs5blBDeUlka0tieTJaWVRnd3p5Tm1KWnd2cUhKSk0KN2hhUFdXTkpSQjMyeGlSTWRHL2JYcnNVL1Rodm5acWxybTVGdENVckpCcXNPaXlZTGs4WGdOZ1pMdzJZcHNQTwpxeWV4bHdvNXcvczk5Sm41a3dQMkdUeTczVnErOVV0TE5SZ3NPdmkweUZObFhTaURJeEdCV0YrTU1pRjZVWmk3CnBRSURBUUFCCi0tLS0tRU5EIFJTQSBQVUJMSUMgS0VZLS0tLS0K","http://123.5.7.1:3000","nexus_2")).to.be.revertedWithCustomError(nodeOperator,"OperatorAlreadyRegistered");
        console.log(await nodeOperator.ssvDKGIP(1));
    });
    it("should update ssv node Operator",async function () {
        await nodeOperator.updateSSVOperatorIP(1,"http://123.5.56.1:3000");
        await expect(nodeOperator.connect(user1).updateSSVOperatorIP(1,"http://123.5.56.1:3000")).to.be.revertedWithCustomError(nodeOperator,"NotOwner");
    });
    it("add cluster", async function () {
        await nodeOperator.registerSSVOperator(3,"LS0tLS1CRUdJTiBSU0EgUFVCTElDIEtFWS0tLS0tCk1JSUJJVEFOQmdrcWhraUc5dzBCQVFFRkFBT0NBUTRBTUlJQkNRS0NBUUJ3amhORXpBLzB4R1lXRDFHRzhWZnAKL01nN0NibVRHNE12alZpaUtzWTNtTnZ1VzZlMWJ6T3JpL2cvRHh3TkpOZmppQlBoRytYb095UnozU2IzWDV5TApMbEhBWXpGbzBaTGd5SFlmaDZ6SG5JTG5rSEYxVXc5aG96REhxcGtUUlZTa1M4YUxFbmxPdnNIRFJZMXExUTlOCm15MGxTODM5eUV4WFN4WWMrNDJDNDVLWUFzWnhFTHpNUm1PYjMzUklqSitNUStTaFhBMC9ZY2xKOEpIWDgvVGkKb3dsMzRpNDIwZVpwV2dBZGFpdElFQzhucjEzeitWeWFINk5QZExYZ0wxdnFnWXpLbFU2aEIwcGwrc3NyWFFuZApiVkNnelZ0alpzeG9ic3A4ZVJqb3hYVzdDeFBmNnlEN09JbnUvUHF2eHd3QXFWb0Rqb3UvSlYySnIzTE5ZODVsCkFnTUJBQUU9Ci0tLS0tRU5EIFJTQSBQVUJMSUMgS0VZLS0tLS0K","http://123.51.7.1:3000","nexus_3");
        await nodeOperator.addCluster([1,2,3],1);
        await expect(nodeOperator.addCluster([1,2,3],1)).to.be.revertedWithCustomError(nodeOperator,"ClusterAlreadyExited");
        await expect(nodeOperator.addCluster([1,2,4,8],2)).to.be.revertedWithCustomError(nodeOperator,"OperatorNotRegistered");
        await expect(nodeOperator.connect(user1).addCluster([1,2,4,8],1)).to.be.revertedWithCustomError(nodeOperator,"NotOwner");
    })
})

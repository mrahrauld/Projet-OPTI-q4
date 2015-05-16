function cout = Question8(donnees)
d = importdata(donnees);
c = [d.cout_materiaux  d.cout_stockage  d.cout_materiaux+(d.cout_heure_sup*(d.duree_assemblage/60))  d.cout_sous_traitant  d.cout_retard d.cout_embauche d.cout_licenciement  d.cout_horaire*35];
NBRE_VAR = 8;
LengthC = NBRE_VAR*d.T;
C=c;
nb_ouvriers=zeros(1,d.T);
for i = 1:d.T
nb_ouvriers(i) = d.nb_ouvriers;
end
for i = 1:d.T-1
C = [C c];
end

%Matrice des contraintes d'égalité Ax=b

Aequal = sparse(2*d.T,d.T*NBRE_VAR);
bequal = zeros(1,2*d.T);
bequal(1) = d.demande(1)-d.stock_initial; % on ajoute le stock initial à la première égalités
Aequal(1,1:8) = [1 -1 1 1 1 0 0 0]; %pas de retard à rattraper ni de stock pour compenser
for i = 2:d.T
    Aequal(i,(1+NBRE_VAR*(i-1)):(NBRE_VAR*(i-1)+8)) = [1 -1 1 1 1 0 0 0];
    Aequal(i,NBRE_VAR*(i-1)-3) = -1;
    Aequal(i,(NBRE_VAR*(i-1))-6) = 1;
    bequal(i) = d.demande(i);
end

Aequal(d.T+1,8)=1;
bequal(1,d.T+1) = d.nb_ouvriers;
for i = d.T+2:2*d.T
    Aequal(i,NBRE_VAR*(i-d.T)) = 1;
    Aequal(i,NBRE_VAR*(i-1-d.T)) = -1;
    Aequal(i,NBRE_VAR*(i-d.T)-1) = 1;
    Aequal(i,NBRE_VAR*(i-d.T)-2) = -1;
end

%Aequal(d.T,(NBRE_VAR*d.T)) = 0; 

%Matrice des contraintes d'inégalité Ax<=b
Aineq = sparse(3*d.T, d.T*NBRE_VAR);
bineq = zeros(1,3*d.T);

for i = 2:d.T
    Aineq(i, ((NBRE_VAR*(i-1)+1)):((NBRE_VAR*(i-1)+8))) = [-1 0 -1 -1 0 0 0 0]; 
    Aineq(i, (NBRE_VAR*i)-3) = 1;
    bineq(1,i) = 0;
end
for i = d.T+1:2*d.T
    Aineq(i, NBRE_VAR*(i-d.T))= -35/(d.duree_assemblage/60);
    Aineq(i, NBRE_VAR*(i-d.T)-7)= 1;
end
for i = 2*d.T+1:3*d.T
    Aineq(i, NBRE_VAR*(i-2*d.T))= -d.nb_max_heure_sup/(d.duree_assemblage/60);
    Aineq(i, NBRE_VAR*(i-2*d.T)-5)= 1;
end


Aineq(1, NBRE_VAR-4) = 1;
Aineq(1, NBRE_VAR-6) = 0;
Aineq(1, NBRE_VAR-3) = 0;

ub = zeros(1,LengthC); % Upper bound
lb = zeros(1,LengthC); % Lower bound
ub(1) = inf;

for i = (8:8:120)
    ub(i-4) = d.nb_max_sous_traitant;
    ub(i-7) = (d.nb_max_ouvriers*35)/(d.duree_assemblage/60);
    ub(i-5) = (d.nb_max_ouvriers*d.nb_max_heure_sup)/(d.duree_assemblage/60);
    ub(i-3) = d.demande(i/8);
    ub(i-6) = inf;
    ub(i-1) = inf;
    ub(i-2) = inf;
    ub(i) = d.nb_max_ouvriers;
    if i == LengthC 
        %retour au Stock initial obligatoire
        ub(i-6) = d.stock_initial;
        lb(i-6) = d.stock_initial;
        % pas de retard la dernière semaine
        ub(i-3) = 0;
    end
end
%ub(8) = d.nb_ouvriers;
%lb(8) = d.nb_ouvriers;
intvars=zeros(1,2*d.T);
options = optimoptions(@linprog, 'Algorithm', 'simplex');%Sol entière si elle existe
tab = reshape(linprog(C,Aineq,bineq,Aequal,bequal,lb,ub,zeros(1,LengthC),options),8,15)';
tab(1:15,9)=d.demande;
tab
[x,cout] =linprog(C,Aineq,bineq,Aequal,bequal,lb,ub,zeros(1,LengthC),options);
